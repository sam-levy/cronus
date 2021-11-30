defmodule Sig.HR.Payslips.Groups do
  import Ecto.Query

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

  def subscribe_to_groups(%Org{} = org) do
    Phoenix.PubSub.subscribe(Sig.PubSub, groups_topic(org))
  end

  def broadcast_new_group(%Org{} = org, %Group{} = group) do
    Phoenix.PubSub.broadcast(Sig.PubSub, groups_topic(org), {:new_payslip_group, group})
  end

  def broadcast_deleted_group(%Org{} = org, %Group{} = group) do
    Phoenix.PubSub.broadcast(Sig.PubSub, groups_topic(org), {:deleted_payslip_group, group})
  end

  defp groups_topic(%Org{} = org), do: "org_id:" <> org.id <> ":payslip_groups"
end
