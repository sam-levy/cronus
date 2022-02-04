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

  describe "insert/2" do
    test "inserts an org" do
      org = insert(:org)

      assert OrgStore.insert({org.id, org}, @test_table) == :ok

      assert {:ok, %Org{} = return} = OrgStore.fetch(org.id, @test_table)

      assert return.id == org.id
      assert return.name == org.name
    end
  end

  describe "fetch/1" do
    test "fetches an org" do
      org = insert(:org)

      assert OrgStore.insert({org.id, org}, @test_table) == :ok

      assert {:ok, %Org{} = return} = OrgStore.fetch(org.id, @test_table)

      assert return.id == org.id
      assert return.name == org.name
    end

    test "invalid id" do
      assert OrgStore.fetch(UUID.generate()) == {:error, :not_found}
    end
  end

  describe "get/1" do
    test "gets an org" do
      org = insert(:org)

      assert OrgStore.insert({org.id, org}, @test_table) == :ok

      assert %Org{} = return = OrgStore.get(org.id, @test_table)

      assert return.id == org.id
      assert return.name == org.name
    end

    test "invalid id" do
      assert OrgStore.get(UUID.generate()) == nil
    end
  end
end
