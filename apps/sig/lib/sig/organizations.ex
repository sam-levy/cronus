defmodule Sig.Organizations do
  alias Sig.Organizations.Org
  alias Sig.Organizations.OrgStore
  alias Sig.Organizations.Positions
  alias Sig.Organizations.Sectors
  alias Sig.Repo

  defdelegate org_sector_change(sector, attrs), to: Sectors, as: :change
  defdelegate org_sector_change(sector_or_attrs \\ %{}), to: Sectors, as: :change
  defdelegate list_org_sectors(org), to: Sectors, as: :list
  defdelegate get_org_sector(org, id), to: Sectors, as: :get
  defdelegate fetch_org_sector_by(filters), to: Sectors, as: :fetch_by
  defdelegate create_org_sector(org, attrs), to: Sectors, as: :create
  defdelegate update_org_sector(sector, attrs), to: Sectors, as: :update
  defdelegate delete_org_sector(sector), to: Sectors, as: :delete
  defdelegate subscribe_to_org_sectors(schema), to: Sectors
  defdelegate broadcast_new_org_sector(sector), to: Sectors
  defdelegate broadcast_updated_org_sector(sector), to: Sectors
  defdelegate broadcast_deleted_org_sector(sector), to: Sectors

  defdelegate org_position_change(position, attrs), to: Positions, as: :change
  defdelegate org_position_change(position_or_attrs \\ %{}), to: Positions, as: :change
  defdelegate list_org_positions(org), to: Positions, as: :list
  defdelegate get_org_position(org, id), to: Positions, as: :get
  defdelegate create_org_position(org, attrs), to: Positions, as: :create
  defdelegate update_org_position(position, attrs), to: Positions, as: :update
  defdelegate delete_org_position(position), to: Positions, as: :delete
  defdelegate subscribe_to_org_positions(schema), to: Positions
  defdelegate broadcast_new_org_position(position), to: Positions
  defdelegate broadcast_updated_org_position(position), to: Positions
  defdelegate broadcast_deleted_org_position(position), to: Positions

  def fetch_org(id) when is_binary(id) do
    case OrgStore.fetch(id) do
      {:ok, org} ->
        {:ok, org}

      {:error, :not_found} ->
        case Repo.get(Org, id) do
          nil ->
            {:error, :not_found}

          %Org{} = org ->
            OrgStore.insert({org.id, org})
            {:ok, org}
        end
    end
  end

  def get_org(id) when is_binary(id) do
    case fetch_org(id) do
      {:ok, org} -> org
      {:error, :not_found} -> nil
    end
  end
end
