defmodule Sig.Finance.Payables.PayablesForPayslip.Authorizer do
  alias Ecto.Multi

  alias Sig.Accounts.User
  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  @fulfilled_payable_message "can't modify a fulfilled payable"
  @authorized_payable_message "can't modify an authorized payable"

  def authorize(%Payslip{}, %Payable{financial_transaction_id: ft_id}, %User{})
      when is_binary(ft_id) do
    {:error, @fulfilled_payable_message}
  end

  def authorize(%Payslip{}, %Payable{authorized_by_id: id}, %User{}) when is_binary(id) do
    {:error, @authorized_payable_message}
  end

  def authorize(%Payslip{} = payslip, %Payable{} = payable, %User{} = user) do
    Multi.new()
    |> Multi.run(:payable, fn _, _ -> ensure_valid_payable_to_authorize(payable) end)
    |> Multi.update(:authorize_payable, fn %{payable: payable} ->
      Payable.authorize_changeset(payable, %{authorized_by_id: user.id})
    end)
    |> Multi.run(:payslip_payable, fn _, %{payable: payable} ->
      PayablesForPayslip.unset_as_auto_adjustable_amount(payslip, payable)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{authorize_payable: payable}} -> {:ok, payable}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp ensure_valid_payable_to_authorize(%Payable{org_id: org_id, id: id}) do
    case Payables.get_by(id: id, org_id: org_id) do
      %Payable{financial_transaction_id: ft_id} when is_binary(ft_id) ->
        {:error, @fulfilled_payable_message}

      %Payable{authorized_by_id: ab_id} when is_binary(ab_id) ->
        {:error, @authorized_payable_message}

      %Payable{} = payable ->
        {:ok, payable}
    end
  end

  def unauthorize(%Payable{financial_transaction_id: ft_id}) when is_binary(ft_id) do
    {:error, @fulfilled_payable_message}
  end

  def unauthorize(%Payable{} = payable) do
    Multi.new()
    |> Multi.run(:payable, fn _, _ -> ensure_valid_payable_to_unauthorize(payable) end)
    |> Multi.update(:unauthorize_payable, fn %{payable: payable} ->
      Payable.unauthorize_changeset(payable)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{unauthorize_payable: payable}} -> {:ok, payable}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp ensure_valid_payable_to_unauthorize(%Payable{org_id: org_id, id: id}) do
    case Payables.get_by(id: id, org_id: org_id) do
      %Payable{financial_transaction_id: nil} = payable -> {:ok, payable}
      %Payable{} -> {:error, @fulfilled_payable_message}
    end
  end
end
