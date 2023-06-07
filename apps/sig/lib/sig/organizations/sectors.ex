defmodule Sig.Organizations.Sectors do
  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.HR
  alias Sig.Organizations.Org
  alias Sig.Organizations.Sector
  alias Sig.Repo

  def change(%Sector{} = sector, %{} = attrs), do: Sector.changeset(sector, attrs)
  def change(%Sector{} = sector), do: Sector.changeset(sector, %{})
  def change(%{} = attrs), do: Sector.changeset(attrs)

  def list(%Org{} = org) do
    Sector
    |> where(org_id: ^org.id)
    |> order_by(:name)
    |> Repo.all()
  end

  def get(%Org{} = org, id) when is_binary(id) do
    Sector
    |> where(org_id: ^org.id)
    |> where(id: ^id)
    |> Repo.one()
  end

  @fetch_by_filters [
    org_id: [type: :string, required: true],
    name: [type: :string]
  ]

  def fetch_by(filters) do
    case NimbleOptions.validate(filters, @fetch_by_filters) do
      {:ok, filters} ->
        Sector
        |> filter_by(filters)
        |> Repo.one()
        |> to_fetch()

      error ->
        error
    end
  end

  # TODO: Refator Sig.Query to accept this functionality
  defp filter_by(queryable, [{key, _values} | _] = filters) when is_atom(key) do
    Enum.reduce(filters, queryable, fn
      {key, nil}, acc -> where(acc, [schema], schema |> field(^key) |> is_nil())
      {key, values}, acc -> where(acc, [schema], field(schema, ^key) in ^List.wrap(values))
    end)
  end

  # TODO: Extract this to Sig.Query
  defp to_fetch(%_module{} = struct), do: {:ok, struct}
  defp to_fetch(nil), do: {:error, :not_found}

  def create(%Org{} = org, %{} = attrs) do
    attrs
    |> Map.put(:org_id, org.id)
    |> Sector.changeset()
    |> Repo.insert()
  end

  def update(%Sector{} = sector, %{} = attrs) do
    sector
    |> Sector.changeset(attrs)
    |> Repo.update()
  end

  def delete(%Sector{} = sector) do
    case HR.count_registrations_by(sector) do
      0 -> Repo.delete(sector)
      _ -> {:error, "Existem registros de funcionários associados"}
    end
  end

  def subscribe_to_org_sectors(schema), do: subscribe(topic(schema))

  def broadcast_new_org_sector(%Sector{} = sector) do
    broadcast(topic(sector), {:new_org_sector, sector})
  end

  def broadcast_updated_org_sector(%Sector{} = sector) do
    broadcast(topic(sector), {:updated_org_sector, sector})
  end

  def broadcast_deleted_org_sector(%Sector{} = sector) do
    broadcast(topic(sector), {:deleted_org_sector, sector})
  end

  defp topic(%Sector{} = sector), do: org_sectors_topic(sector.org_id)
  defp topic(%Org{} = org), do: org_sectors_topic(org.id)

  defp org_sectors_topic(org_id) do
    "org_id:" <> org_id <> ":org_sectors"
  end
end
