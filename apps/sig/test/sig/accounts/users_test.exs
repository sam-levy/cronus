defmodule Sig.Accounts.UsersTest do
  use Sig.DataCase, async: true

  alias Sig.Accounts
  alias Sig.Accounts.{User, Users, UserToken}
  alias Sig.Entities.Individuals.Individual

  @endpoint SigLive.Endpoint

  describe "list_users/2" do
    test "lists users from an org ordered by email" do
      org = insert(:org)

      insert(:user, org: org, email: "user_b@test.com")
      insert(:user, org: org, email: "user_a@test.com")

      assert [
               %User{email: "user_a@test.com"},
               %User{email: "user_b@test.com"}
             ] = Users.list_users(org)
    end

    test "preloads" do
      org = insert(:org)

      insert(:user, org: org)

      assert [
               %User{individual: %Individual{}}
             ] = Users.list_users(org, preload: :individual)
    end

    test "org has no user" do
      org = insert(:org)

      assert Users.list_users(org) == []
    end
  end

  describe "disable_user/1" do
    test "disables a user" do
      user = insert(:user)

      assert {:ok, %User{disabled_at: %NaiveDateTime{}}} = Users.disable_user(user)
    end

    test "deletes user tokens" do
      user = insert(:user)
      _ = Accounts.generate_user_session_token(user)

      assert {:ok, %User{disabled_at: %NaiveDateTime{}}} = Users.disable_user(user)

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "enable_user/1" do
    test "enables a user" do
      user = insert(:user, disabled_at: NaiveDateTime.utc_now())

      assert {:ok, %User{disabled_at: nil}} = Users.enable_user(user)
    end
  end

  describe "subscribe_to_users/1" do
    test "subscribes to users topic" do
      org = insert(:org)
      topic = "org_id:" <> org.id <> ":users"

      assert Users.subscribe_to_users(org) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_users, :users}
      )

      assert_receive {:updated_users, :users}
    end
  end

  describe "broadcast_users/1" do
    test "broadcasts users from an organization" do
      org = insert(:org)
      right_users = insert_list(2, :user, org: org)
      _wrong_users = insert_list(2, :user)

      topic = "org_id:" <> org.id <> ":users"

      @endpoint.subscribe(topic)

      assert Users.broadcast_users(org) == :ok

      assert_receive {:updated_users, received_users}

      assert Enum.count(received_users) == 2

      Enum.each(right_users, fn user ->
        assert received_user = Enum.find(received_users, &(&1.id == user.id))

        assert received_user.org_id == user.org_id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
