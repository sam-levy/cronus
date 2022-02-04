defmodule Sig.OrganizationsTest do
  use Sig.DataCase, async: true

  alias Sig.Organizations
  alias Sig.Organizations.Org
  alias Sig.Organizations.OrgStore

  describe "fetch_org/1" do
    test "fetches an org" do
      org = insert(:org)

      assert {:ok, %Org{} = return} = Organizations.fetch_org(org.id)

      assert return.id == org.id
      assert return.name == org.name
    end

    test "adds org to org store" do
      org = insert(:org)

      assert {:ok, %Org{}} = Organizations.fetch_org(org.id)

      assert {:ok, %Org{} = return} = OrgStore.fetch(org.id)

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

    test "adds org to org store" do
      org = insert(:org)

      assert %Org{} = Organizations.get_org(org.id)

      assert %Org{} = return = OrgStore.get(org.id)

      assert return.id == org.id
      assert return.name == org.name
    end

    test "invalid id" do
      assert Organizations.get_org(UUID.generate()) == nil
    end
  end
end
