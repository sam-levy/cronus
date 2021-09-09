defmodule Sig.Organizations.Entities.EntityTest do
  use Sig.DataCase

  alias Sig.Organizations.Entities.Entity
  alias Sig.Organizations.Entities.Individual.Gender

  describe "new_individual_changeset/1" do
    test "valid params" do
      organzation_id = UUID.generate()

      individual_params = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender),
        organization_id: organzation_id
      }

      entity_params = %{
        individual: individual_params
      }

      assert changeset = Entity.new_individual_changeset(entity_params)

      assert changeset.valid?

      assert %{
               individual: individual_changeset
             } = changeset.changes

      assert individual_changeset.changes == %{
               name: individual_params[:name],
               cpf: individual_params[:cpf],
               gender: String.to_atom(individual_params[:gender]),
               organization_id: organzation_id
             }
    end

    test "missing required params" do
      assert changeset = Entity.new_individual_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               individual: ["can't be blank"]
             }
    end
  end

  describe "new_real_company_changeset/1" do
    test "valid params" do
      organzation_id = UUID.generate()

      company_params = %{
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organzation_id
      }

      entity_params = %{
        company: company_params
      }

      assert changeset = Entity.new_real_company_changeset(entity_params)

      assert changeset.valid?

      assert %{
               company: company_changeset
             } = changeset.changes

      assert company_changeset.changes == %{
               trade_name: company_params[:trade_name],
               registration_name: company_params[:registration_name],
               cnpj: company_params[:cnpj],
               organization_id: organzation_id
             }
    end
  end

  describe "new_virtual_company_changeset/1" do
    test "valid params" do
      organzation_id = UUID.generate()

      company_params = %{
        trade_name: Faker.Company.name(),
        organization_id: organzation_id
      }

      entity_params = %{
        company: company_params
      }

      assert changeset = Entity.new_virtual_company_changeset(entity_params)

      assert changeset.valid?

      assert %{
               company: company_changeset
             } = changeset.changes

      assert company_changeset.changes == %{
               trade_name: company_params[:trade_name],
               organization_id: organzation_id,
               is_virtual: true
             }
    end
  end
end
