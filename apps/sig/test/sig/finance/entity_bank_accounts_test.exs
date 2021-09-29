defmodule Sig.Finance.Banks.EntityBankAccountsTest do
  use Sig.DataCase

  alias Sig.Entities.Entity
  alias Sig.Entities.Individuals.Individual
  alias Sig.Entities.Companies.Company
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %EntityBankAccount{}} = EntityBankAccounts.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %EntityBankAccount{}} =
               EntityBankAccounts.update_change(%EntityBankAccount{}, %{})

      assert %Ecto.Changeset{data: %EntityBankAccount{}} =
               EntityBankAccounts.update_change(%EntityBankAccount{})
    end
  end

  describe "list_by_entity_with_account/1" do
    test "lists EntityBankAccount by entity ordered by routing_number preloaded with Account" do
      %{id: org_id} = org = insert(:org)
      %{id: entity_id} = entity = insert(:entity, org: org)

      account_1 = insert(:bank_account, org: org, entity: entity, routing_number: "104")

      %{bank_account_id: account_id_1} =
        insert(:entity_bank_account, org: org, entity: entity, bank_account: account_1)

      account_2 = insert(:bank_account, org: org, entity: entity, routing_number: "001")

      %{bank_account_id: account_id_2} =
        insert(:entity_bank_account, org: org, entity: entity, bank_account: account_2)

      _to_ignore_1 = insert(:entity_bank_account, org: org)
      _to_ignore_2 = insert(:entity_bank_account)

      assert [
               %EntityBankAccount{
                 org_id: ^org_id,
                 entity_id: ^entity_id,
                 bank_account_id: ^account_id_2,
                 bank_account: %Account{}
               },
               %EntityBankAccount{
                 org_id: ^org_id,
                 entity_id: ^entity_id,
                 bank_account_id: ^account_id_1,
                 bank_account: %Account{}
               }
             ] = EntityBankAccounts.list_by_entity_with_account(entity)
    end

    test "entity has no EntityBankAccount" do
      entity = insert(:entity)

      assert EntityBankAccounts.list_by_entity_with_account(entity) == []
    end
  end

  describe "get_with_holder/2" do
    test "gets an EnityBankAccount preloaded with the Account holder Entity and Individual" do
      org = insert(:org)

      individual = insert(:individual, org: org)

      %{entity_id: holder_entity_id} = holder_individual = insert(:individual, org: org)

      %{id: account_id} =
        holder_account = insert(:bank_account, org: org, entity: holder_individual.entity)

      insert(:entity_bank_account,
        org: org,
        entity: individual.entity,
        bank_account: holder_account
      )

      assert %EntityBankAccount{
               bank_account: %Account{
                 id: ^account_id,
                 entity: %Entity{
                   id: ^holder_entity_id,
                   individual: %Individual{}
                 }
               }
             } = EntityBankAccounts.get_with_holder(individual.entity, account_id)
    end

    test "gets an EnityBankAccount preloaded with the Account holder Entity and Company" do
      org = insert(:org)

      company = insert(:company, org: org)

      %{entity_id: holder_entity_id} = holder_company = insert(:company, org: org)

      %{id: account_id} =
        holder_account = insert(:bank_account, org: org, entity: holder_company.entity)

      insert(:entity_bank_account, org: org, entity: company.entity, bank_account: holder_account)

      assert %EntityBankAccount{
               bank_account: %Account{
                 id: ^account_id,
                 entity: %Entity{
                   id: ^holder_entity_id,
                   company: %Company{}
                 }
               }
             } = EntityBankAccounts.get_with_holder(company.entity, account_id)
    end
  end

  describe "fetch_entity_primary/1" do
    test "gets the entity primary EntityBankAccount" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      %{bank_account_id: primary_eba_account_id} =
        insert(:entity_bank_account, org: org, entity: entity, is_primary: true)

      insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      assert {:ok, %EntityBankAccount{bank_account_id: ^primary_eba_account_id}} =
               EntityBankAccounts.fetch_entity_primary(entity)
    end

    test "when entity doesn't have a primary EntityBankAccount" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      assert EntityBankAccounts.fetch_entity_primary(entity) == {:error, :not_found}
    end

    test "when entity doesn't have any EntityBankAccount" do
      entity = insert(:entity)

      assert EntityBankAccounts.fetch_entity_primary(entity) == {:error, :not_found}
    end
  end

  describe "entities_relationships/2" do
    test "returns the possible relationships for two entities" do
      assert EntityBankAccounts.entities_relationships(
               %Entity{type: :individual},
               %Entity{type: :individual}
             ) == [:child, :spouse, :partner]

      assert EntityBankAccounts.entities_relationships(
               %Entity{type: :individual},
               %Entity{type: :company}
             ) == [:company_owner]

      assert EntityBankAccounts.entities_relationships(
               %Entity{type: :company},
               %Entity{type: :individual}
             ) == [:company_owner]

      assert EntityBankAccounts.entities_relationships(
               %Entity{type: :company},
               %Entity{type: :company}
             ) == [:same_owner_company]
    end
  end

  describe "subscribe_to_entity_bank_accounts/1" do
    test "subscribes to bank accounts topic" do
      entity = insert(:entity)
      topic = "entity_id:" <> entity.id <> ":entity_bank_accounts"

      assert EntityBankAccounts.subscribe_to_entity_bank_accounts(entity) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_entity_bank_accounts, :entity_bank_accounts}
      )

      assert_receive {:updated_entity_bank_accounts, :entity_bank_accounts}
    end
  end

  describe "broadcast_entity_bank_accounts/1" do
    test "broadcasts bank accounts from an entity" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      _right_ebas = insert_list(2, :entity_bank_account, org: org, entity: entity)
      _wrong_ebas = insert_list(2, :entity_bank_account)

      topic = "entity_id:" <> entity.id <> ":entity_bank_accounts"

      @endpoint.subscribe(topic)

      assert EntityBankAccounts.broadcast_entity_bank_accounts(entity) == :ok

      assert_receive {:updated_entity_bank_accounts, received_ebas}

      assert Enum.count(received_ebas) == 2

      Enum.each(received_ebas, fn eba ->
        assert eba.org_id == org.id
        assert eba.entity_id == entity.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
