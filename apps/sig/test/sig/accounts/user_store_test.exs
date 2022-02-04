defmodule Sig.Accounts.UserStoreTest do
  use Sig.DataCase, async: true

  alias Sig.Accounts.UserStore
  alias Sig.Accounts.User

  @test_table :user_store_test

  setup do
    start_supervised!({UserStore, name: @test_table})

    allow = Process.whereis(@test_table)

    Ecto.Adapters.SQL.Sandbox.allow(Sig.Repo, self(), allow)

    :ok
  end

  describe "insert/2" do
    test "inserts an user" do
      user = insert(:user)

      assert UserStore.insert({user.id, user}, @test_table) == :ok

      assert {:ok, %User{} = return} = UserStore.fetch(user.id, @test_table)

      assert return.id == user.id
      assert return.email == user.email
    end
  end

  describe "fetch/2" do
    test "fetches an user" do
      user = insert(:user)

      assert UserStore.insert({user.id, user}, @test_table) == :ok

      assert {:ok, %User{} = return} = UserStore.fetch(user.id, @test_table)

      assert return.id == user.id
      assert return.email == user.email
    end

    test "invalid token" do
      assert UserStore.fetch(UUID.generate(), @test_table) == {:error, :not_found}
    end
  end

  describe "delete/2" do
    test "deletes an user" do
      user = insert(:user)

      assert UserStore.insert({user.id, user}, @test_table) == :ok

      assert {:ok, %User{} = return} = UserStore.fetch(user.id, @test_table)

      assert return.id == user.id
      assert return.email == user.email

      assert UserStore.delete(user.id, @test_table) == :ok

      assert UserStore.fetch(user.id, @test_table) == {:error, :not_found}
    end
  end
end
