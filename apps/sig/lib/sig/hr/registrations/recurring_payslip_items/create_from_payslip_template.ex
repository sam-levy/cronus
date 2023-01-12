defmodule Sig.HR.Registrations.RecurringPayslipItems.CreateFromPayslipTemplate do
  alias Sig.HR
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RecurringPayslipItems
  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem
  alias Sig.Repo

  def call(%Registration{} = registration, payslip_template_id)
      when is_binary(payslip_template_id) do
    %{registration: registration, payslip_template_id: payslip_template_id}
    |> Extep.new()
    |> Extep.run(&validate_no_recurring_payslip_items/1)
    |> Extep.run(&list_template_items/1, :payslip_template_items)
    |> Extep.run(&validate_unique_category_code/1)
    |> Extep.run(&build_attrs/1, :attrs)
    |> Extep.return(&insert_all/1)
  end

  def validate_no_recurring_payslip_items(context) do
    case RecurringPayslipItems.count_by(context.registration) do
      0 -> :ok
      _ -> {:error, "o holerite modelo deve estar vazio"}
    end
  end

  defp list_template_items(context) do
    attrs = [
      org_id: context.registration.org_id,
      payslip_template_id: context.payslip_template_id
    ]

    case HR.list_payslip_template_items_by(attrs) do
      [] -> {:error, "não há items no modelo de holerite"}
      items -> {:ok, items}
    end
  end

  defp validate_unique_category_code(%{payslip_template_items: items}) do
    Enum.reduce_while(items, MapSet.new(), fn item, acc ->
      if MapSet.member?(acc, item.category_code),
        do: {:halt, {:error, "Existem itens duplicados no modelo de holerite"}},
        else: {:cont, MapSet.put(acc, item.category_code)}
    end)
    |> case do
      %MapSet{} -> :ok
      {:error, message} -> {:error, message}
    end
  end

  defp build_attrs(context) do
    %{registration: regsitration, payslip_template_items: template_items} = context

    template_items
    |> Enum.reduce_while([], &handle_attrs(&1, &2, regsitration))
    |> case do
      attrs when is_list(attrs) -> {:ok, attrs}
      {:error, changeset} -> {:error, changeset}
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

  def handle_changeset(%{valid?: true} = changeset, acc),
    do: {:cont, [Sig.Changeset.add_timestamps_placeholders(changeset.changes) | acc]}

  def handle_changeset(%{valid?: false} = changeset, _acc), do: {:halt, {:error, changeset}}

  defp insert_all(%{attrs: attrs}) do
    attrs_count = Enum.count(attrs)
    insert_all_opts = Sig.Changeset.add_timestamps_placeholders_opts(returning: true)

    RecurringPayslipItem
    |> Repo.insert_all(attrs, insert_all_opts)
    |> case do
      {insert_count, items} when insert_count == attrs_count -> {:ok, items}
      _ -> {:error, nil}
    end
  end
end
