defmodule Sig.Finance.Banks.Accounts.BackUpdaterTest do
  use Sig.DataCase, async: true

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.Accounts.BackUpdater

  describe "handle_existing_primary_account/3" do
    test "no existing primary account" do
      entity = insert(:entity)

      existing_account = insert(:bank_account, org: entity.org, entity: entity, is_primary: false)

      assert BackUpdater.handle_existing_primary_account(entity, %{is_primary: true}) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_account(entity, %{is_primary: false}) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_account(entity, %{other_attr: "value"}) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_account(
               entity,
               %{is_primary: true},
               existing_account
             ) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_account(
               entity,
               %{is_primary: false},
               existing_account
             ) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_account(
               entity,
               %{other_attr: "value"},
               existing_account
             ) ==
               {:ok, nil}
    end

    test "doesn't update when the account being updated IS the existing primary account" do
      entity = insert(:entity)

      existing_primary_account =
        insert(:bank_account, org: entity.org, entity: entity, is_primary: true)

      assert {:ok, %Account{is_primary: true}} =
               BackUpdater.handle_existing_primary_account(
                 entity,
                 %{is_primary: false},
                 existing_primary_account
               )
    end

    test "Set the existing primary account to false when the account being updated is NOT the existing primary one." do
      entity = insert(:entity)

      existing_primary_account =
        insert(:bank_account, org: entity.org, entity: entity, is_primary: true)

      account = insert(:bank_account, org: entity.org, entity: entity, is_primary: false)

      assert {:ok, %Account{}} =
               BackUpdater.handle_existing_primary_account(
                 entity,
                 %{is_primary: true},
                 account
               )

      assert Repo.get_by(Account, id: existing_primary_account.id, is_primary: false)
    end

    test "Set the existing primary account to false when it's an insertion of a primary account" do
      entity = insert(:entity)

      existing_primary_account =
        insert(:bank_account, org: entity.org, entity: entity, is_primary: true)

      assert {:ok, %Account{}} =
               BackUpdater.handle_existing_primary_account(entity, %{is_primary: true})

      assert Repo.get_by(Account, id: existing_primary_account.id, is_primary: false)
    end

    test "attrs is_primary false" do
      entity = insert(:entity)

      existing_primary_account =
        insert(:bank_account, org: entity.org, entity: entity, is_primary: true)

      account = insert(:bank_account, org: entity.org, entity: entity, is_primary: false)

      # Updating the existing primary account
      assert {:ok, %Account{}} =
               BackUpdater.handle_existing_primary_account(
                 entity,
                 %{is_primary: false},
                 existing_primary_account
               )

      assert Repo.get_by(Account, id: existing_primary_account.id, is_primary: true)

      # Updating another account
      assert {:ok, %Account{}} =
               BackUpdater.handle_existing_primary_account(
                 entity,
                 %{is_primary: false},
                 account
               )

      assert Repo.get_by(Account, id: existing_primary_account.id, is_primary: true)

      # Inserting new account
      assert {:ok, %Account{}} =
               BackUpdater.handle_existing_primary_account(
                 entity,
                 %{is_primary: false}
               )

      assert Repo.get_by(Account, id: existing_primary_account.id, is_primary: true)
    end

    test "attrs without is_primary key" do
      entity = insert(:entity)

      existing_primary_account =
        insert(:bank_account, org: entity.org, entity: entity, is_primary: true)

      account = insert(:bank_account, org: entity.org, entity: entity, is_primary: false)

      # Updating the existing primary account
      assert {:ok, %Account{}} =
               BackUpdater.handle_existing_primary_account(
                 entity,
                 %{other_attr: "value"},
                 existing_primary_account
               )

      assert Repo.get_by(Account, id: existing_primary_account.id, is_primary: true)

      # Updating another account
      assert {:ok, %Account{}} =
               BackUpdater.handle_existing_primary_account(
                 entity,
                 %{other_attr: "value"},
                 account
               )

      assert Repo.get_by(Account, id: existing_primary_account.id, is_primary: true)

      # Inserting new account
      assert {:ok, %Account{}} =
               BackUpdater.handle_existing_primary_account(
                 entity,
                 %{other_attr: "value"}
               )

      assert Repo.get_by(Account, id: existing_primary_account.id, is_primary: true)
    end
  end
end
