defmodule Sig.HR.Registrations.RecurringPayslipItems.ListByRegistration do
  import Ecto.Query

  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Salaries
  alias Sig.HR.Registrations.Benefits
  alias Sig.Repo

  def call(%Registration{} = registration, opts \\ []) do
    case list_recurring_payslip_items(registration) do
      [] ->
        []

      items ->
        start_date = Keyword.get(opts, :start_date, Date.utc_today())

        %{registration: registration, items: items, start_date: start_date}
        |> Extep.new()
        |> Extep.run(&index_items/1, :indexed_items)
        |> Extep.run(&handle_salary_amount/1, :salary_amount)
        |> Extep.run(&handle_benefit_types/1, :indexed_benefits)
        |> Extep.run(&handle_benefits/1, :indexed_benefits)
        |> Extep.return(&handle_virtual_fields/1)
    end
  end

  defp index_items(%{items: items}) do
    indexed_items = Enum.reduce(items, %{}, &handle_index/2)

    {:ok, indexed_items}
  end

  defp handle_index(%RecurringPayslipItem{type: :outside_item} = item, acc),
    do: Sig.Map.flat_put(acc, :outside_item, item)

  defp handle_index(%RecurringPayslipItem{type: :payslip_item} = item, acc),
    do: Sig.Map.flat_put(acc, :payslip_item, item)

  defp handle_index(
         %RecurringPayslipItem{
           type: :payslip_item_model,
           payslip_recurring_item_model: %{is_fixed_amount: true}
         } = item,
         acc
       ) do
    Sig.Map.flat_put(acc, :payslip_item_model, item)
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
    Sig.Map.flat_put(acc, {:payslip_item_model, :employee_salary}, item)
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
    Sig.Map.flat_put(acc, {:payslip_item_model, :employee_benefit}, item)
  end

  defp handle_salary_amount(%{indexed_items: indexed_items, start_date: start_date} = context) do
    if Map.has_key?(indexed_items, {:payslip_item_model, :employee_salary}) do
      salary_in_effect = Salaries.in_effect_on_date(context.registration, start_date)

      salary_amount = if salary_in_effect, do: salary_in_effect.amount, else: Money.new(0)

      {:ok, salary_amount}
    else
      {:ok, nil}
    end
  end

  defp handle_benefit_types(%{indexed_items: indexed_items}) do
    case Map.get(indexed_items, {:payslip_item_model, :employee_benefit}, []) do
      [] ->
        {:ok, %{}}

      benefit_items ->
        indexed_benefits =
          Map.new(
            benefit_items,
            &{&1.payslip_recurring_item_model.employee_benefit_type_percentage_target, []}
          )

        {:ok, indexed_benefits}
    end
  end

  defp handle_benefits(%{indexed_benefits: map}) when map == %{}, do: {:ok, %{}}

  defp handle_benefits(%{indexed_benefits: indexed_benefits} = context) do
    benefits =
      Benefits.list_by_registration(context.registration,
        types: Map.keys(indexed_benefits),
        in_effect_on_date: context.start_date
      )

    {:ok, Enum.reduce(benefits, %{}, &Sig.Map.flat_put(&2, &1.type, &1))}
  end

  defp handle_virtual_fields(%{indexed_items: indexed_items} = context) do
    salary_amount = Map.get(context, :salary_amount)
    indexed_benefits = Map.get(context, :indexed_benefits)

    indexed_items
    |> Enum.flat_map(&fill_virtual_fields(&1, salary_amount, indexed_benefits))
    |> Enum.sort_by(&handle_sort(&1.code))
  end

  defp handle_sort(string) when is_binary(string), do: string
  defp handle_sort(_), do: "ZZZ"

  defp fill_virtual_fields({:outside_item, items}, _salary_amount, _indexed_benefits) do
    Enum.map(items, fn item ->
      %{
        item
        | description: item.outside_item_description,
          entry_type: item.outside_item_entry_type,
          is_payment_advance: item.outside_item_is_payment_advance,
          amount: item.item_amount
      }
    end)
  end

  defp fill_virtual_fields({:payslip_item, items}, _salary_amount, _indexed_benefits) do
    Enum.map(items, fn item ->
      %{
        description: description,
        entry_type: entry_type,
        is_payment_advance: is_payment_advance,
        code: code
      } = item.payslip_category

      %{
        item
        | description: description,
          entry_type: entry_type,
          is_payment_advance: is_payment_advance,
          code: code,
          amount: item.item_amount
      }
    end)
  end

  defp fill_virtual_fields({:payslip_item_model, items}, _salary_amount, _indexed_benefits) do
    Enum.map(items, fn item ->
      %{
        description: description,
        entry_type: entry_type,
        is_payment_advance: is_payment_advance,
        code: code
      } = item.payslip_recurring_item_model.category

      %{
        item
        | description: description,
          entry_type: entry_type,
          is_payment_advance: is_payment_advance,
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
      %{
        description: description,
        entry_type: entry_type,
        is_payment_advance: is_payment_advance,
        code: code
      } = item.payslip_recurring_item_model.category

      percentage = item.payslip_recurring_item_model.percentage / 100

      %{
        item
        | description: description,
          entry_type: entry_type,
          is_payment_advance: is_payment_advance,
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
      %{
        description: description,
        entry_type: entry_type,
        is_payment_advance: is_payment_advance,
        code: code
      } = item.payslip_recurring_item_model.category

      %{employee_benefit_type_percentage_target: benefit_type, percentage: percentage} =
        item.payslip_recurring_item_model

      %{
        item
        | description: description,
          entry_type: entry_type,
          is_payment_advance: is_payment_advance,
          code: code,
          amount: handle_benefit_amount(indexed_benefits, benefit_type, percentage)
      }
    end)
  end

  defp handle_benefit_amount(indexed_benefits, benefit_type, percentage) do
    case Map.get(indexed_benefits, benefit_type) do
      nil ->
        Money.new(0)

      [%{amount: amount}] ->
        Money.multiply(amount, percentage / 100)

      benefits ->
        Enum.reduce(benefits, 0, fn %{amount: amount}, acc ->
          amount
          |> Money.multiply(percentage / 100)
          |> Money.add(acc)
        end)
    end
  end

  defp list_recurring_payslip_items(registration) do
    registration
    |> query_by_registration()
    |> preload_payslip_category()
    |> preload_payslip_recurring_item_model()
    |> Repo.all()
  end

  defp query_by_registration(registration) do
    from(item in RecurringPayslipItem, as: :item)
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end

  defp preload_payslip_category(query) do
    query
    |> join(:left, [item: item], _ in assoc(item, :payslip_category), as: :payslip_category)
    |> preload([payslip_category: payslip_category], payslip_category: payslip_category)
  end

  defp preload_payslip_recurring_item_model(query) do
    query
    |> join(:left, [item: item], _ in assoc(item, :payslip_recurring_item_model),
      as: :recurring_item_model
    )
    |> join(:left, [recurring_item_model: model], _ in assoc(model, :category),
      as: :recurring_item_model_category
    )
    |> preload(
      [
        recurring_item_model: recurring_item_model,
        recurring_item_model_category: recurring_item_model_category
      ],
      payslip_recurring_item_model:
        {recurring_item_model, category: recurring_item_model_category}
    )
  end
end
