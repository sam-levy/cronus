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
end
