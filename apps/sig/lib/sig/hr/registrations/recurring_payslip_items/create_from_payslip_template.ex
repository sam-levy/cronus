defmodule Sig.HR.Registrations.RecurringPayslipItems.CreateFromPayslipTemplate do
  alias Ecto.Multi

  alias Sig.HR
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RecurringPayslipItems
  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              return: nil,
              registration: nil,
              payslip_template_id: nil,
              payslip_template_items: nil,
              recurring_payslip_items_attrs: nil
  end

  def call(%Registration{} = registration, template_id) when is_binary(template_id) do
    %Context{registration: registration, payslip_template_id: template_id}
    |> validate_no_recurring_payslip_items()
    |> list_template_items()
    |> validate_unique_category_code()
    |> build_attrs()
    |> insert_all_multi()
    |> handle_return()
  end

  def validate_no_recurring_payslip_items(context) do
    case RecurringPayslipItems.count_by(context.registration) do
      0 -> context
      _ -> error(context, "o holerite modelo deve estar vazio")
    end
  end

  defp list_template_items(%{status: :halted} = context), do: context

  defp list_template_items(context) do
    attrs = [
      org_id: context.registration.org_id,
      payslip_template_id: context.payslip_template_id
    ]

    case HR.list_payslip_template_items_by(attrs) do
      [] -> error(context, "não há items no modelo de holerite")
      items -> %{context | payslip_template_items: items}
    end
  end

  defp validate_unique_category_code(%{status: :halted} = context), do: context

  defp validate_unique_category_code(%{payslip_template_items: items} = context) do
    Enum.reduce_while(items, MapSet.new(), fn item, acc ->
      if MapSet.member?(acc, item.category_code) do
        {:halt, {:error, "Existem itens duplicados no modelo de holerite"}}
      else
        {:cont, MapSet.put(acc, item.category_code)}
      end
    end)
    |> case do
      %MapSet{} -> context
      {:error, message} -> error(context, message)
    end
  end

  defp build_attrs(%{status: :halted} = context), do: context

  defp build_attrs(context) do
    %{registration: regsitration, payslip_template_items: template_items} = context

    template_items
    |> Enum.reduce_while([], &handle_attrs(&1, &2, regsitration))
    |> case do
      attrs when is_list(attrs) -> %{context | recurring_payslip_items_attrs: attrs}
      {:error, changeset} -> error(context, changeset)
    end
  end

  defp handle_attrs(%{type: :payslip_item} = item, acc, registration) do
    %{
      org_id: registration.org_id,
      registration_id: registration.id,
      payslip_category_id: item.payslip_category_id,
      item_amount: item.amount
    }
    |> RecurringPayslipItems.create_change(:payslip_item)
    |> handle_changeset(acc)
  end

  defp handle_attrs(%{type: :payslip_item_model} = item, acc, registration) do
    %{
      org_id: registration.org_id,
      registration_id: registration.id,
      payslip_recurring_item_model_id: item.payslip_recurring_item_model.id
    }
    |> RecurringPayslipItems.create_change(:payslip_item_model)
    |> handle_changeset(acc)
  end

  def handle_changeset(%{valid?: true} = changeset, acc) do
    {:cont, [Sig.Changeset.add_timestamps(changeset.changes) | acc]}
  end

  def handle_changeset(%{valid?: false} = changeset, _acc) do
    {:halt, {:error, changeset}}
  end

  defp insert_all_multi(%{status: :halted} = context), do: context

  defp insert_all_multi(context) do
    %{recurring_payslip_items_attrs: attrs} = context

    Multi.new()
    |> Multi.insert_all(:recurring_payslip_items, RecurringPayslipItem, attrs, returning: true)
    |> Repo.transaction()
    |> case do
      {:error, _operation, reason, _changes} -> error(context, reason)
      {:ok, %{recurring_payslip_items: {_, items}}} -> %{context | return: items}
    end
  end

  defp error(context, error), do: %{context | status: :halted, return: {:error, error}}

  defp handle_return(%{status: :ok, return: return}), do: {:ok, return}
  defp handle_return(%{status: :halted, return: {:error, error}}), do: {:error, error}
end
