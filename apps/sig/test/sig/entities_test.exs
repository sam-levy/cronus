defmodule Sig.EntitiesTest do
  use Sig.DataCase

  alias Sig.Entities
  alias Sig.Entities.Entity
  alias Sig.Entities.Companies.Company
  alias Sig.Entities.Individuals.Individual

  describe "fetch_by_document/2" do
    test "fetches an entity by CPF" do
      org = insert(:org)

      %{entity_id: entity_id} = insert(:individual, org: org, cpf: "443.167.600-76")

      assert {:ok, %Entity{id: ^entity_id, individual: %Individual{}}} =
               Entities.fetch_by_document(org, "443.167.600-76")

      assert {:ok, %Entity{id: ^entity_id, individual: %Individual{}}} =
               Entities.fetch_by_document(org, "44316760076")

      assert {:ok, %Entity{id: ^entity_id, individual: %Individual{}}} =
               Entities.fetch_by_document(org, "  443 .167600- 76 ")

      assert Entities.fetch_by_document(org, "invalid") == :error
    end

    test "fetches an entity by CNPJ" do
      org = insert(:org)

      %{entity_id: entity_id} = insert(:company, org: org, cnpj: "24.421.337/0001-30")

      assert {:ok, %Entity{id: ^entity_id, company: %Company{}}} =
               Entities.fetch_by_document(org, "24.421.337/0001-30")

      assert {:ok, %Entity{id: ^entity_id, company: %Company{}}} =
               Entities.fetch_by_document(org, "24421337000130")

      assert {:ok, %Entity{id: ^entity_id, company: %Company{}}} =
               Entities.fetch_by_document(org, "  24421. 3370001  -30 ")

      assert Entities.fetch_by_document(org, "invalid") == :error
    end
  end

  describe "fetch_by_cpf/2" do
    test "fetches an entity by CPF" do
      org = insert(:org)

      %{entity_id: entity_id} = insert(:individual, org: org, cpf: "706.401.430-08")

      assert {:ok, %Entity{id: ^entity_id, individual: %Individual{}}} =
               Entities.fetch_by_cpf(org, "706.401.430-08")

      assert {:ok, %Entity{id: ^entity_id, individual: %Individual{}}} =
               Entities.fetch_by_cpf(org, "70640143008")

      assert {:ok, %Entity{id: ^entity_id, individual: %Individual{}}} =
               Entities.fetch_by_cpf(org, " . 706401 430 -08 ")

      assert Entities.fetch_by_cpf(org, "invalid") == :error
    end
  end

  describe "fetch_by_cnpj/2" do
    test "fetches an entity by CNPJ" do
      org = insert(:org)

      %{entity_id: entity_id} = insert(:company, org: org, cnpj: "64.904.123/0001-30")

      assert {:ok, %Entity{id: ^entity_id, company: %Company{}}} =
               Entities.fetch_by_cnpj(org, "64.904.123/0001-30")

      assert {:ok, %Entity{id: ^entity_id, company: %Company{}}} =
               Entities.fetch_by_cnpj(org, " . 64904.  1230001 -30 ")

      assert {:ok, %Entity{id: ^entity_id, company: %Company{}}} =
               Entities.fetch_by_cnpj(org, "64904.123 0001 -30")

      assert Entities.fetch_by_cnpj(org, "invalid") == :error
    end
  end

  describe "get_name/1" do
    test "returns the name of an Individual" do
      entity = %Entity{type: :individual, individual: %Individual{name: "John Doe"}}

      assert Entities.get_name(entity) == "John Doe"
    end

    test "returns the trade name of a Company if not nil" do
      entity = %Entity{type: :company, company: %Company{trade_name: "Acme", registration_name: "Acme LLC"}}

      assert Entities.get_name(entity) == "Acme"
    end

    test "returns the registration name of a Company if the trade name is nil" do
      entity = %Entity{type: :company, company: %Company{trade_name: nil, registration_name: "Acme LLC"}}

      assert Entities.get_name(entity) == "Acme LLC"
    end

    test "returns when no preloaded Company or Individual" do
      assert Entities.get_name(%Entity{}) == nil
    end
  end
end
