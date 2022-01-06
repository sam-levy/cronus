defmodule Sig.HR.Payslips.BatchCreator do
  import Ecto.Changeset

  alias Ecto.Multi
  alias Ecto.UUID

  alias Sig.Finance
  alias Sig.Finance.Payables
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.BatchCreator.Attrs
  alias Sig.HR.Payslips.Groups
  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Payslips.PayslipGroupType
  alias Sig.HR.Registrations
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RecurringPayslipItems
  alias Sig.Organizations.Org
  alias Sig.Repo

  defmodule Attrs do
    defstruct [:type, :start_date, :sectors_ids]
  end

  def changeset(%{} = params \\ %{}) do
    types = %{type: PayslipGroupType, start_date: :date, sectors_ids: {:array, UUID}}

    {%Attrs{}, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:type, :start_date, :sectors_ids])
  end

  @spec verify(Org.t(), map()) ::
          {:ok, list(Registration.t())} | {:error, Ecto.Changeset.t() | String.t()}
  def verify(%Org{} = org, %{} = attrs) do
    Multi.new()
    |> base_multi(org, attrs)
    |> Multi.run(:payslips_attrs, fn _, changes ->
      {:ok, build_payslips_attrs(changes, org, attrs)}
    end)
    |> Multi.run(:rollback, fn _, _ -> {:error, nil} end)
    |> Repo.transaction()
    |> handle_verify_return(org)
  end

  @spec create(Org.t(), map(), list()) ::
          {:ok, list(Payslip.t())} | {:error, Ecto.Changeset.t() | String.t()}
  def create(%Org{} = org, %{} = attrs, opts \\ []) do
    Multi.new()
    |> base_multi(org, attrs)
    |> Multi.insert_all(:payslips, Payslip, &build_payslips_attrs(&1, org, attrs), returning: true)
    |> Multi.run(:payslip_items_attrs, &build_payslip_items_attrs/2)
    |> Multi.insert_all(:payslip_items, Item, & &1.payslip_items_attrs, returning: true)
    |> Multi.run(:indexed_payslip_items, &index_payslip_items/2)
    |> Multi.merge(&update_payslips_amounts/1)
    |> Multi.merge(&create_payables(&1, opts))
    |> Repo.transaction()
    |> handle_create_return()
  end

  defp base_multi(multi, org, attrs) do
    multi
    |> Multi.run(:batch_create_attrs, fn _, _ -> build_batch_create_attrs(attrs) end)
    |> Multi.run(:indexed_registrations, &index_registrations(&1, &2, org))
    |> Multi.run(:group, &provide_group(&1, &2, org))
    |> Multi.run(:indexed_existing_group_payslips, &index_existing_group_payslips/2)
  end

  defp build_batch_create_attrs(attrs) do
    case changeset(attrs) do
      %{valid?: true, changes: changes} -> {:ok, changes}
      changeset -> {:error, changeset}
    end
  end

  defp index_registrations(_, %{batch_create_attrs: attrs}, org) do
    %{start_date: start_date, sectors_ids: sectors_ids} = attrs

    end_date = Date.end_of_month(start_date)

    case Registrations.list_by(org,
           active_in_period: [start_date: start_date, end_date: end_date],
           sectors_ids: sectors_ids
         ) do
      [] -> {:error, "Não existem registros de funcionários para os setores nesta data"}
      registrations -> {:ok, Map.new(registrations, &{&1.id, &1})}
    end
  end

  defp provide_group(_, %{batch_create_attrs: attrs}, org) do
    Groups.provide(org, attrs.start_date, attrs.type)
  end

  defp index_existing_group_payslips(_, %{group: {:new, _}}), do: {:ok, %{}}

  defp index_existing_group_payslips(_, %{group: {:existing, group}}) do
    {:ok, group |> Payslips.list_by() |> Map.new(&{&1.registration_id, &1})}
  end

  defp build_payslips_attrs(changes, org, attrs) do
    %{
      group: {_, group},
      indexed_registrations: indexed_registrations,
      indexed_existing_group_payslips: indexed_existing_group_payslips
    } = changes

    Enum.reduce(indexed_registrations, [], fn {_, registration}, acc ->
      if Map.get(indexed_existing_group_payslips, registration.id) do
        acc
      else
        start_date =
          attrs.start_date
          |> Date.beginning_of_month()
          |> Sig.Date.get_max(registration.admission_date)

        end_date =
          start_date
          |> Date.end_of_month()
          |> Sig.Date.get_min(registration.resignation_date)

        %{
          start_date: start_date,
          end_date: end_date,
          type: attrs.type,
          org_id: org.id,
          group_id: group.id,
          registration_id: registration.id
        }
        |> Payslip.create_changeset()
        |> case do
          %{valid?: true} = changeset -> [build_payslip_item_attrs(changeset) | acc]
          _ -> acc
        end
      end
    end)
  end

  defp build_payslip_items_attrs(_repo, changes) do
    %{indexed_registrations: indexed_registrations, payslips: {_, payslips}} = changes

    Enum.reduce_while(payslips, [], fn payslip, acc ->
      start_date = Date.beginning_of_month(payslip.start_date)

      indexed_registrations
      |> Map.get(payslip.registration_id)
      |> RecurringPayslipItems.list_by_registration(start_date: start_date)
      |> Enum.reduce_while(
        %{codes: MapSet.new(), attrs: []},
        &validate_payslip_item_attrs(&1, &2, payslip)
      )
      |> case do
        %{attrs: attrs} -> {:cont, [attrs | acc]}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      attrs when is_list(attrs) -> {:ok, List.flatten(attrs)}
      {:error, error} -> {:error, error}
    end
  end

  defp validate_payslip_item_attrs(rpi, acc, payslip) do
    with {:duplicated_rpi, false} <- {:duplicated_rpi, duplicated_rpi?(acc, rpi)},
         %{valid?: true} = changeset <- Items.build_changeset_from(rpi, payslip) do
      attrs = build_payslip_item_attrs(changeset)

      {:cont, handle_acc(acc, attrs)}
    else
      {:duplicated_rpi, true} -> {:halt, handle_duplicated_recurring_payslip_item(payslip)}
      %{valid?: false} = changeset -> {:halt, {:error, changeset}}
    end
  end

  defp handle_duplicated_recurring_payslip_item(payslip) do
    name = get_individual_name(payslip)

    {:error,
     "Existem itens duplicados no holerite modelo de #{name}. Favor corrigir antes de gerar os holerites."}
  end

  defp get_individual_name(payslip) do
    registration =
      Registrations.get_by([org_id: payslip.org_id, id: payslip.registration_id],
        preload: :individual
      )

    registration.individual.name
  end

  defp duplicated_rpi?(_acc, %{type: :outside_item}), do: false
  defp duplicated_rpi?(acc, %{code: code}), do: MapSet.member?(acc.codes, code)

  defp build_payslip_item_attrs(changeset) do
    changeset.changes
    |> Map.drop([:category_id])
    |> Sig.Changeset.add_timestamps()
  end

  defp handle_acc(acc, %{type: :outside_item} = attrs) do
    Sig.Map.flat_put(acc, :attrs, attrs)
  end

  defp handle_acc(acc, %{type: :payslip_item, code: code} = attrs) do
    codes = MapSet.put(acc.codes, code)

    acc
    |> Sig.Map.flat_put(:attrs, attrs)
    |> Map.put(:codes, codes)
  end

  defp index_payslip_items(_, %{payslip_items: {_, payslip_items}}) do
    indexed_payslip_items =
      Enum.reduce(payslip_items, %{}, fn item, acc ->
        Map.put(acc, item.payslip_id, [item | Map.get(acc, item.payslip_id, [])])
      end)

    {:ok, indexed_payslip_items}
  end

  defp update_payslips_amounts(changes) do
    %{payslips: {_, payslips}, indexed_payslip_items: indexed_payslip_items} = changes

    Enum.reduce(payslips, Multi.new(), fn payslip, multi ->
      payslip_items = Map.get(indexed_payslip_items, payslip.id, [])

      case Payslips.calculate_payslip_items_amount(payslip_items) do
        %Money{amount: amount} when amount < 0 ->
          handle_payslip_negative_amount(multi, payslip)

        %Money{amount: amount} when amount == payslip.amount.amount ->
          multi

        %Money{amount: amount} ->
          changeset = Payslip.update_amount_changeset(payslip, %{amount: amount})

          Multi.update(multi, {:update_payslip_amount, payslip.id}, changeset)
      end
    end)
  end

  defp handle_payslip_negative_amount(multi, payslip) do
    name = get_individual_name(payslip)

    Multi.error(
      multi,
      {:update_payslip_amount, payslip.id},
      "O total do holerite modelo de #{name} está negativo. Favor corrigir antes de gerar os holerites."
    )
  end

  defp create_payables(changes, opts) do
    %{
      payslips: {_, payslips},
      indexed_registrations: indexed_registrations,
      indexed_payslip_items: indexed_payslip_items
    } = changes

    Enum.reduce(payslips, Multi.new(), fn payslip, multi ->
      registration = Map.get(indexed_registrations, payslip.registration_id)
      payslip_items = Map.get(indexed_payslip_items, payslip.id, [])

      Multi.run(multi, {:payables_for_payslip, payslip.id}, fn _, _ ->
        case Finance.create_payables_for_payslip(registration, payslip, payslip_items, opts) do
          {:ok, payables} -> {:ok, payables}
          {:error, message} when is_binary(message) -> raise(ArgumentError, message)
          {:error, changeset} when is_struct(changeset) -> raise(ArgumentError, Sig.Changeset.errors_to_string(changeset))
        end
      end)
    end)
  end

  defp handle_verify_return({:error, :rollback, _reason, %{payslips_attrs: payslips_attrs}}, org) do
    registration_ids = Enum.map(payslips_attrs, & &1.registration_id)

    registrations =
      Registrations.list_by_ids(org, registration_ids,
        preload: [:individual, :sector, :registered_at],
        order_by: :individual_name
      )

    {:ok, registrations}
  end

  defp handle_verify_return({:error, _operation, reason, _changes}, _org), do: {:error, reason}

  defp handle_create_return({:error, _operation, reason, _changes}), do: {:error, reason}

  defp handle_create_return({:ok, %{group: {:existing, _}, payslips: {_, payslips}} = changes}) do
    Task.start(fn -> broadcast_payslips(changes) end)

    {:ok, payslips}
  end

  defp handle_create_return({:ok, %{group: {:new, group}, payslips: {_, payslips}} = changes}) do
    Task.start(fn ->
      Groups.broadcast_new_group(group)
      broadcast_payslips(changes)
    end)

    {:ok, payslips}
  end

  defp broadcast_payslips(%{payslips: {_, payslips}} = changes) do
    Enum.each(payslips, fn payslip ->
      Payslips.broadcast_new_payslip(payslip)

      changes
      |> Map.get({:payables_for_payslip, payslip.id}, [])
      |> Enum.each(&Payables.broadcast_new_payable/1)
    end)
  end
end
