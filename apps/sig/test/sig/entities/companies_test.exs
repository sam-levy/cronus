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
end
