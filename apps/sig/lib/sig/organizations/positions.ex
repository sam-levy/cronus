defmodule Sig.Organizations.Positions do
  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.HR
  alias Sig.Organizations.Org
  alias Sig.Organizations.Position
  alias Sig.Repo

  def change(%Position{} = position, %{} = attrs), do: Position.changeset(position, attrs)
  def change(%Position{} = position), do: Position.changeset(position, %{})
  def change(%{} = attrs), do: Position.changeset(attrs)

  def list(%Org{} = org) do
    Position
    |> where(org_id: ^org.id)
    |> order_by(:name)
    |> Repo.all()
  end

  def get(%Org{} = org, id) when is_binary(id) do
    Position
    |> where(org_id: ^org.id)
    |> where(id: ^id)
    |> Repo.one()
  end

  def create(%Org{} = org, %{} = attrs) do
    attrs
    |> Map.put(:org_id, org.id)
    |> Position.changeset()
    |> Repo.insert()
  end

  def update(%Position{} = position, %{} = attrs) do
    position
    |> Position.changeset(attrs)
    |> Repo.update()
  end

  def delete(%Position{} = position) do
    case HR.count_registrations_by(position) do
      0 -> Repo.delete(position)
      _ -> {:error, "Existem registros de funcionários associados"}
    end
  end

  def subscribe_to_org_positions(schema), do: subscribe(topic(schema))

  def broadcast_new_org_position(%Position{} = position) do
    broadcast(topic(position), {:new_org_position, position})
  end

  def broadcast_updated_org_position(%Position{} = position) do
    broadcast(topic(position), {:updated_org_position, position})
  end

  def broadcast_deleted_org_position(%Position{} = position) do
    broadcast(topic(position), {:deleted_org_position, position})
  end

  defp topic(%Position{} = position), do: org_positions_topic(position.org_id)
  defp topic(%Org{} = org), do: org_positions_topic(org.id)

  defp org_positions_topic(org_id) do
    "org_id:" <> org_id <> ":org_positions"
  end
end
