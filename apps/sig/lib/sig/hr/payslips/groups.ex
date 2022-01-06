defmodule Sig.HR.Payslips.Groups do
  import Ecto.Query
  import Sig.Broadcaster

  alias Ecto.Multi

  alias Sig.Finance.Payables
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Groups.Group
  alias Sig.Organizations.Org
  alias Sig.Repo

  def list_by(%Org{} = org) do
    Group
    |> where(org_id: ^org.id)
    |> order_by(desc: :date)
    |> Repo.all()
  end

  def get(%Org{} = org, id) when is_binary(id) do
    Group
    |> where(org_id: ^org.id)
    |> where(id: ^id)
    |> Repo.one()
  end

  def fetch(%Org{} = org, id) when is_binary(id) do
    case get(org, id) do
      %Group{} = group -> {:ok, group}
      nil -> {:error, :not_found}
    end
  end

  def fetch_by(attrs) when is_list(attrs) do
    case Repo.get_by(Group, attrs) do
      %Group{} = group -> {:ok, group}
      nil -> {:error, :not_found}
    end
  end

  def create(%Org{} = org, %{} = attrs) do
    attrs
    |> Map.put(:org_id, org.id)
    |> Group.create_changeset()
    |> Repo.insert()
  end

  def provide(%Org{} = org, %Date{} = date, type) when is_atom(type) do
    date = Date.beginning_of_month(date)

    with nil <- Repo.get_by(Group, org_id: org.id, date: date, type: type),
         {:ok, group} <- create(org, %{date: date, type: type}) do
      {:ok, {:new, group}}
    else
      %Group{} = group -> {:ok, {:existing, group}}
      {:error, _} = error -> error
    end
  end

  def delete(%Group{} = group) do
    Group
    |> where(org_id: ^group.org_id)
    |> where(id: ^group.id)
    |> select([group], group)
    |> Repo.delete_all()
    |> case do
      {1, [group]} -> {:ok, group}
      _ -> {:error, :not_found}
    end
  end

  def delete_with_payslips(%Org{} = org, %Group{} = group) do
    payslip_ids = group |> Payslips.list_by() |> Enum.map(& &1.id)

    Multi.new()
    |> Multi.run(:delete_payslips, fn _, _ -> Payslips.delete_by_ids(org, payslip_ids) end)
    |> Multi.run(:group, fn _, _ -> delete(group) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{group: group, delete_payslips: %{payslips: payslips, payables: payables}}} when is_list(payslips) ->
        Task.start(fn ->
          broadcast_deleted_group(group)
          Enum.each(payslips, &Payslips.broadcast_deleted_payslip/1)
          if payables, do: Enum.each(payables, &Payables.broadcast_deleted_payable/1)
        end)

        {:ok, group}

      {:ok, %{group: group, delete_payslips: nil}} ->
        broadcast_deleted_group(group)

        {:ok, group}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  def subscribe_to_groups(schema), do: subscribe(topic(schema))

  def broadcast_new_group(%Group{} = group) do
    broadcast(topic(group), {:new_payslip_group, group})
  end

  def broadcast_deleted_group(%Group{} = group) do
    broadcast(topic(group), {:deleted_payslip_group, group})
  end

  defp topic(%Group{} = group), do: org_groups_topic(group.org_id)
  defp topic(%Org{} = org), do: org_groups_topic(org.id)

  defp org_groups_topic(org_id) do
    "org_id:" <> org_id <> ":payslip_groups"
  end
end
