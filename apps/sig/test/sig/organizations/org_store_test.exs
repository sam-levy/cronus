defmodule Sig.Organizations.OrgStoreTest do
  use Sig.DataCase, async: true

  alias Sig.Organizations.OrgStore
  alias Sig.Organizations.Org

  @test_table :org_store_test

  setup do
    start_supervised!({OrgStore, name: @test_table})

    allow = Process.whereis(@test_table)

    Ecto.Adapters.SQL.Sandbox.allow(Sig.Repo, self(), allow)

    :ok
  end

  describe "fetch_org/1" do
    test "fetches an org" do
      org = insert(:org)

      OrgStore.refresh_store(@test_table)

      assert {:ok, %Org{} = return} = OrgStore.fetch_org(org.id, @test_table)

      assert return.id == org.id
      assert return.name == org.name
    end

    test "invalid id" do
      assert OrgStore.fetch_org(UUID.generate()) == {:error, :not_found}
    end
  end

  describe "get_org/1" do
    test "gets an org" do
      org = insert(:org)

      OrgStore.refresh_store(@test_table)

      assert %Org{} = return = OrgStore.get_org(org.id, @test_table)

      assert return.id == org.id
      assert return.name == org.name
    end

    test "invalid id" do
      assert OrgStore.get_org(UUID.generate()) == nil
    end
  end
end
