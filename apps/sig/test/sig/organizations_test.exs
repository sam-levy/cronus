defmodule Sig.OrganizationsTest do
  use Sig.DataCase

  alias Sig.Organizations
  alias Sig.Organizations.Sector
  alias Sig.Organizations.Position
  alias Sig.Organizations.Org

  describe "fetch_org/1" do
    test "fetches an org" do
      org = insert(:org)

      assert {:ok, %Org{} = return} = Organizations.fetch_org(org.id)

      assert return.id == org.id
      assert return.name == org.name
    end

    test "invalid id" do
      assert Organizations.fetch_org(UUID.generate()) == {:error, :not_found}
    end
  end

  describe "get_org/1" do
    test "gets an org" do
      org = insert(:org)

      assert %Org{} = return = Organizations.get_org(org.id)

      assert return.id == org.id
      assert return.name == org.name
    end

    test "invalid id" do
      assert Organizations.get_org(UUID.generate()) == nil
    end
  end

  describe "list_sectors/1" do
    test "lists sectors ordered by name" do
      org = insert(:org)
      insert(:org_sector, org: org, name: "finance")
      insert(:org_sector, org: org, name: "accounting")

      assert [
               %Sector{name: "accounting"},
               %Sector{name: "finance"}
             ] = Organizations.list_sectors(org)
    end

    test "when org has no sectors" do
      org = insert(:org)

      assert Organizations.list_sectors(org) == []
    end
  end

  describe "list_positions/1" do
    test "lists positions ordered by name" do
      org = insert(:org)
      insert(:org_position, org: org, name: "cooker")
      insert(:org_position, org: org, name: "clerk")

      assert [
               %Position{name: "clerk"},
               %Position{name: "cooker"}
             ] = Organizations.list_positions(org)
    end

    test "when org has no positions" do
      org = insert(:org)

      assert Organizations.list_positions(org) == []
    end
  end
end
