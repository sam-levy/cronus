defmodule Sig.Finance.FinancialTransactions.Creator do
  defmodule Attrs do
    use Sig.Changeset

    alias Ecto.UUID
    alias Sig.Enums.FinancialTransaction

    @schema %{
      description: :string,
      type: FinancialTransaction.Type,
      placement_date: :date,
      clearing_date: :date,
      payable_ids: {:array, UUID},
      bank_account_id: UUID,
      created_by_id: UUID
    }

    @fields Map.keys(@schema)

    defstruct @fields

    def changeset(%{} = params \\ %{}) do
      {%Attrs{}, @schema}
      |> cast(params, @fields)
      |> validate_required([:description, :type, :placement_date, :payable_ids, :created_by_id])
      |> validate_required_if(:type, FinancialTransaction.bank_types(), :bank_account_id)
      |> validate_length(:description, max: 255)
      |> validate_dates(:clearing_date, [:gt, :eq], :placement_date)
      |> validate_non_empty_list(:payable_ids)
    end
  end

  import Ecto.Query
  import Sig.Enums.FinancialTransaction, only: [is_bank_type: 1]

  alias Ecto.Multi

  alias Sig.Extep
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.FinancialTransactions.BankTransactions.BankTransaction
  alias Sig.Finance.FinancialTransactions.Creator.Attrs
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Organizations.Org
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              org: nil,
              attrs: nil,
              payables: nil,
              amount: nil,
              changeset: nil,
              financial_transaction: nil
  end

  def pay_payables_change(%{} = params \\ %{}), do: Attrs.changeset(params)

  def pay_payables(%Org{} = org, %{} = attrs) do
    %Context{org: org, attrs: attrs}
    |> Extep.new()
    |> Extep.run(&validate_attrs/1)
    |> Extep.run(&list_payables/1)
    |> Extep.run(&validate_payables/1)
    |> Extep.run(&validate_bank_account/1)
    |> Extep.run(&build_financial_transaction_changeset/1)
    |> Extep.run(&create_multi/1)
    |> Extep.return(:financial_transaction)
  end

  defp validate_attrs(%{attrs: attrs} = context) do
    case Attrs.changeset(attrs) do
      %{valid?: true, changes: changes} -> %{context | attrs: changes}
      changeset -> {:error, changeset}
    end
  end

  defp list_payables(context) do
    %{org: org, attrs: attrs} = context

    payable_ids = Enum.uniq(attrs.payable_ids)
    payables = Payables.list_by(org, payable_ids: payable_ids)
    payables_count = Enum.count(payables)

    if payables_count == Enum.count(payable_ids) do
      %{context | payables: payables}
    else
      {:error, "Existem pagáveis não encontrados"}
    end
  end

  defp validate_payables(%{attrs: %{type: :check}, payables: [payable]} = context) do
    if payable.check_debit_bank_account_id == context.attrs.bank_account_id do
      %{context | amount: payable.amount}
    else
      {:error, "A conta bancária deve ser igual a do cheque"}
    end
  end

  defp validate_payables(%{attrs: %{type: :check}, payables: [_ | _]}) do
    {:error, "Não é possivel fazer pagamentos em lote de contas em cheque"}
  end

  defp validate_payables(context) do
    %{attrs: %{type: type}, payables: payables} = context

    case Enum.reduce_while(payables, Money.new(0), &validate_payable(&1, &2, type)) do
      %Money{} = amount -> %{context | amount: amount}
      {:error, message} -> {:error, message}
    end
  end

  defp validate_payable(payable, acc, type) do
    with {:same_type, true} <- {:same_type, payable.financial_transaction_type == type},
         {:authorized, true} <- {:authorized, payable.authorized_by_id != nil},
         {:not_paid, true} <- {:not_paid, payable.financial_transaction_id == nil} do
      {:cont, Money.add(acc, payable.amount)}
    else
      {:same_type, false} ->
        {:halt, {:error, "Existem pagáveis com métodos de pagamento diferentes"}}

      {:authorized, false} ->
        {:halt, {:error, "Existem pagáveis não autorizados"}}

      {:not_paid, false} ->
        {:halt, {:error, "Existem pagáveis que já foram pagos"}}
    end
  end

  defp validate_bank_account(%{attrs: %{type: type}} = context) when is_bank_type(type) do
    %{org: org, attrs: %{bank_account_id: id}} = context

    case Accounts.fetch(org, id) do
      {:ok, %{is_managed: true}} -> context
      {:ok, %{is_managed: false}} -> {:error, "A conta não é administrada"}
      {:error, :not_found} -> {:error, "Conta não encontrada"}
    end
  end

  defp validate_bank_account(context), do: context

  defp build_financial_transaction_changeset(context) do
    %{org: org, attrs: attrs, amount: amount} = context

    attrs
    |> Map.put(:org_id, org.id)
    |> Map.put(:amount, amount)
    |> Map.put(:entry_type, :debit)
    |> FinancialTransaction.create_changeset()
    |> case do
      %{valid?: true} = changeset -> %{context | changeset: changeset}
      changeset -> {:error, changeset}
    end
  end

  defp create_multi(context) do
    %{org: org, attrs: attrs, payables: payables, changeset: changeset, amount: amount} = context

    payable_ids = Enum.map(payables, & &1.id)

    Multi.new()
    |> Multi.insert(:financial_transaction, changeset)
    |> Multi.merge(&insert_underling(&1, org, attrs))
    |> Multi.update_all(:payables, &update_payables_query(&1, org, payable_ids), [])
    |> Multi.run(:validate_payables_amount, &validate_payables_amount(&1, &2, amount))
    |> Repo.transaction()
    |> case do
      {:ok, %{financial_transaction: ft}} ->
        Task.Supervisor.start_child(
          Sig.BroadcastSupervisor,
          fn ->
            Payables.broadcast_payables(org, payable_ids)
          end,
          restart: :transient
        )


        %{context | financial_transaction: ft}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  defp insert_underling(%{financial_transaction: %{type: type} = ft}, org, attrs)
       when is_bank_type(type) do
    Multi.insert(Multi.new(), :bank_transaction, %BankTransaction{
      org_id: org.id,
      financial_transaction_id: ft.id,
      bank_account_id: attrs.bank_account_id
    })
  end

  defp insert_underling(_transaction, _org, _attrs), do: Multi.new()

  defp update_payables_query(%{financial_transaction: ft}, org, payable_ids) do
    Payable
    |> where(org_id: ^org.id)
    |> where([p], p.id in ^payable_ids)
    |> update(set: [financial_transaction_id: ^ft.id])
    |> select([p], p)
  end

  defp validate_payables_amount(_repo, %{payables: {_, payables}}, amount) do
    if Enum.reduce(payables, Money.new(0), &Money.add(&1.amount, &2)) == amount do
      {:ok, nil}
    else
      {:error, "difference in payables amount sum"}
    end
  end
end
