defmodule Sig.HR.Registrations.RecurringPayslipItems.ListByRegistration do
  import Ecto.Query

  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Salaries
  alias Sig.HR.Registrations.Vouchers
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              start_date: nil,
              registration: nil,
              indexed_items: %{},
              salary_amount: nil,
              indexed_benefits: %{}
  end

  def call(%Registration{} = registration, %Date{} = start_date \\ Date.utc_today()) do
    context = %Context{registration: registration, start_date: start_date}

    registration
    |> query_by_registration()
    |> preload_payslip_category()
    |> preload_payslip_recurring_item_model()
    |> Repo.all()
    |> put_in_context(context)
    |> handle_salary_amount()
    |> handle_benefit_types()
    |> handle_benefits()
    |> handle_virtual_fields()
  end

  defp put_in_context([], context), do: %{context | status: :halted}

  defp put_in_context(result, context) do
    %{context | indexed_items: Enum.reduce(result, %{}, &handle_index/2)}
  end

  defp handle_index(%RecurringPayslipItem{type: :outside_item} = item, acc) do
    put_item(acc, :outside_item, item)
  end

  defp handle_index(%RecurringPayslipItem{type: :payslip_item} = item, acc) do
    put_item(acc, :payslip_item, item)
  end

  defp handle_index(
         %RecurringPayslipItem{
           type: :payslip_item_model,
           payslip_recurring_item_model: %{is_fixed_amount: true}
         } = item,
         acc
       ) do
    put_item(acc, :payslip_item_model, item)
  end

  defp handle_index(
         %RecurringPayslipItem{
           type: :payslip_item_model,
           payslip_recurring_item_model: %{
             is_fixed_amount: false,
             percentage_target: :employee_salary
           }
         } = item,
         acc
       ) do
    put_item(acc, {:payslip_item_model, :employee_salary}, item)
  end

  defp handle_index(
         %RecurringPayslipItem{
           type: :payslip_item_model,
           payslip_recurring_item_model: %{
             is_fixed_amount: false,
             percentage_target: :employee_benefit
           }
         } = item,
         acc
       ) do
    put_item(acc, {:payslip_item_model, :employee_benefit}, item)
  end

  defp handle_salary_amount(%{status: :halted} = context), do: context

  defp handle_salary_amount(%{indexed_items: indexed_items, start_date: start_date} = context) do
    if Map.has_key?(indexed_items, {:payslip_item_model, :employee_salary}) do
      salary_in_effect = Salaries.in_effect_on_date(context.registration, start_date)

      salary_amount = if salary_in_effect, do: salary_in_effect.amount, else: Money.new(0)

      %{context | salary_amount: salary_amount}
    else
      context
    end
  end

  defp handle_benefit_types(%{status: :halted} = context), do: context

  defp handle_benefit_types(%{indexed_items: indexed_items} = context) do
    case Map.get(indexed_items, {:payslip_item_model, :employee_benefit}, []) do
      [] ->
        context

      benefit_items ->
        indexed_benefits =
          Map.new(
            benefit_items,
            &{&1.payslip_recurring_item_model.employee_benefit_type_percentage_target, []}
          )

        %{context | indexed_benefits: indexed_benefits}
    end
  end

  defp handle_benefits(%{status: :halted} = context), do: context

  defp handle_benefits(%{indexed_benefits: map} = context) when map == %{}, do: context

  defp handle_benefits(%{indexed_benefits: indexed_benefits} = context) do
    benefits =
      Vouchers.list_by_registration(context.registration,
        types: Map.keys(indexed_benefits),
        in_effect_on_date: context.start_date
      )

    %{context | indexed_benefits: Map.new(benefits, &{&1.type, &1})}
  end

  defp handle_virtual_fields(%{status: :halted}), do: []

  defp handle_virtual_fields(%{indexed_items: indexed_items} = context) do
    salary_amount = Map.get(context, :salary_amount)
    indexed_benefits = Map.get(context, :indexed_benefits)

    indexed_items
    |> Enum.flat_map(&fill_virtual_fields(&1, salary_amount, indexed_benefits))
    |> Enum.sort_by(&to_integer(&1.code))
  end

  defp fill_virtual_fields({:outside_item, items}, _salary_amount, _indexed_benefits) do
    Enum.map(items, fn item ->
      %{
        item
        | description: item.outside_item_description,
          entry_type: item.outside_item_entry_type,
          amount: item.item_amount
      }
    end)
  end

  defp fill_virtual_fields({:payslip_item, items}, _salary_amount, _indexed_benefits) do
    Enum.map(items, fn item ->
      %{description: description, entry_type: entry_type, code: code} = item.payslip_category

      %{
        item
        | description: description,
          entry_type: entry_type,
          code: code,
          amount: item.item_amount
      }
    end)
  end

  defp fill_virtual_fields({:payslip_item_model, items}, _salary_amount, _indexed_benefits) do
    Enum.map(items, fn item ->
      %{description: description, entry_type: entry_type, code: code} =
        item.payslip_recurring_item_model.category

      %{
        item
        | description: description,
          entry_type: entry_type,
          code: code,
          amount: item.payslip_recurring_item_model.amount
      }
    end)
  end

  defp fill_virtual_fields(
         {{:payslip_item_model, :employee_salary}, items},
         salary_amount,
         _indexed_benefits
       ) do
    Enum.map(items, fn item ->
      %{description: description, entry_type: entry_type, code: code} =
        item.payslip_recurring_item_model.category

      percentage = item.payslip_recurring_item_model.percentage / 100

      %{
        item
        | description: description,
          entry_type: entry_type,
          code: code,
          amount: Money.multiply(salary_amount, percentage)
      }
    end)
  end

  defp fill_virtual_fields(
         {{:payslip_item_model, :employee_benefit}, items},
         _salary,
         indexed_benefits
       ) do
    Enum.map(items, fn item ->
      %{description: description, entry_type: entry_type, code: code} =
        item.payslip_recurring_item_model.category

      %{employee_benefit_type_percentage_target: benefit_type, percentage: percentage} =
        item.payslip_recurring_item_model

      %{
        item
        | description: description,
          entry_type: entry_type,
          code: code,
          amount: handle_benefit_amount(indexed_benefits, benefit_type, percentage)
      }
    end)
  end

  defp handle_benefit_amount(indexed_benefits, benefit_type, percentage) do
    case Map.get(indexed_benefits, benefit_type) do
      nil -> Money.new(0)
      %{amount: amount} -> Money.multiply(amount, percentage / 100)
    end
  end

  defp to_integer(string) when is_binary(string) do
    String.to_integer(string)
  rescue
    _ -> string
  end

  defp to_integer(_), do: nil

  defp put_item(map, key, item) do
    existing_items = Map.get(map, key, [])
    updated_items = [item | existing_items]

    Map.put(map, key, updated_items)
  end

  defp query_by_registration(registration) do
    RecurringPayslipItem
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end

  defp preload_payslip_category(query) do
    query
    |> join(:left, [item], recurring_item_model in assoc(item, :payslip_category),
      as: :payslip_category
    )
    |> preload([item, payslip_category: payslip_category], payslip_category: payslip_category)
  end

  defp preload_payslip_recurring_item_model(query) do
    query
    |> join(:left, [item], recurring_item_model in assoc(item, :payslip_recurring_item_model),
      as: :recurring_item_model
    )
    |> join(:left, [_, recurring_item_model: model], category in assoc(model, :category),
      as: :recurring_item_model_category
    )
    |> preload(
      [
        _,
        recurring_item_model: recurring_item_model,
        recurring_item_model_category: recurring_item_model_category
      ],
      payslip_recurring_item_model:
        {recurring_item_model, category: recurring_item_model_category}
    )
  end
end
