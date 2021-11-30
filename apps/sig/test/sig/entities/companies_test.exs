defmodule Sig.Entities.CompaniesTest do
  use Sig.DataCase

  alias Sig.Entities.Companies
  alias Sig.Entities.Companies.Company

  describe "fetch/2" do
    test "fetches a company" do
      org = insert(:org)
      %{entity_id: entity_id} = insert(:company, org: org)

      assert {:ok, %Company{entity_id: ^entity_id}} = Companies.fetch(org, entity_id)
    end

    test "company from another org" do
      org = insert(:org)
      %{entity_id: entity_id} = insert(:company, org: org)

      another_org = insert(:org)

      assert Companies.fetch(another_org, entity_id) == {:error, :not_found}
    end

    test "company doesn't exist" do
      org = insert(:org)

      assert Companies.fetch(org, UUID.generate()) == {:error, :not_found}
    end
  end

  describe "list/1" do
    test "lists companies from an org ordered by trade name" do
      org = insert(:org)

      insert(:company, org: org, trade_name: "Dunder Mifflin")
      insert(:company, org: org, trade_name: "Acme")

      _to_ignore = insert(:company)

      assert [
               %Company{trade_name: "Acme"},
               %Company{trade_name: "Dunder Mifflin"}
             ] = Companies.list(org)
    end

    test "lists companies from an org with filters" do
      org = insert(:org)

      insert(:company, org: org, trade_name: "Dunder Mifflin")
      insert(:virtual_company, org: org, trade_name: "OCP")
      insert(:virtual_company, org: org, trade_name: "Acme")

      _to_ignore = insert(:virtual_company)

      assert [
               %Company{trade_name: "Acme"},
               %Company{trade_name: "OCP"}
             ] = Companies.list(org, filter: [is_virtual: true])
    end

    test "when org has no company" do
      org = insert(:org)

      assert Companies.list(org) == []
    end
  end

  describe "get_by_registration_with_entity/1" do
    test "gets a company by registration" do
      org = insert(:org)
      entity = insert(:entity, org: org)
      %{entity_id: entity_id} = company = insert(:company, org: org, entity: entity)
      registration = insert(:employee_registration, org: org, registered_at: company)

      assert %Company{entity_id: ^entity_id} =
               Companies.get_by_registration_with_entity(registration)
    end
  end
end
