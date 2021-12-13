defmodule Sig.Organizations do
  alias Sig.Organizations.Org
  alias Sig.Organizations.Positions
  alias Sig.Organizations.Sectors
  alias Sig.Repo

  defdelegate org_sector_change(sector, attrs), to: Sectors, as: :change
  defdelegate org_sector_change(sector_or_attrs \\ %{}), to: Sectors, as: :change
  defdelegate list_org_sectors(org), to: Sectors, as: :list
  defdelegate get_org_sector(org, id), to: Sectors, as: :get
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

  def fetch_org(org_id) when is_binary(org_id) do
    case Repo.get(Org, org_id) do
      %Org{} = org -> {:ok, org}
      nil -> {:error, :not_found}
    end
  end

  def get_org(org_id) when is_binary(org_id) do
    Repo.get(Org, org_id)
  end
end
