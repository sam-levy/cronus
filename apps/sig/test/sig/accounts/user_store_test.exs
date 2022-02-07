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

    test "deletes multiple records" do
      %{id: user_1_id} = user_1 = insert(:user)
      %{id: user_2_id} = user_2 = insert(:user)

      assert UserStore.insert({user_1.id, user_1}, @test_table) == :ok
      assert UserStore.insert({user_2.id, user_2}, @test_table) == :ok

      assert {:ok, %User{id: ^user_1_id}} = UserStore.fetch(user_1.id, @test_table)
      assert {:ok, %User{id: ^user_2_id}} = UserStore.fetch(user_2.id, @test_table)

      assert UserStore.delete([user_1.id, user_2.id], @test_table) == :ok

      assert UserStore.fetch(user_1.id, @test_table) == {:error, :not_found}
      assert UserStore.fetch(user_2.id, @test_table) == {:error, :not_found}
    end

    test "when user is not found" do
      assert UserStore.delete(UUID.generate(), @test_table) == :ok
    end
  end
end
