defmodule Sig.HR.Registrations.CreateTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Create
  alias Sig.HR.Registrations.Registration

  describe "call/3" do
    test "creates a registration" do
      org = insert(:org)

      other_company = insert(:company, org: org)

      individual = insert(:individual, org: org)
      company = insert(:company, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)

      _other_company_open_registration =
        insert(:employee_registration,
          org: org,
          individual: individual,
          registered_at: other_company,
          admission_date: ~D[2008-01-01]
        )

      _same_company_closed_registration =
        insert(:employee_registration,
          org: org,
          individual: individual,
          registered_at: company,
          admission_date: ~D[2005-01-01],
          resignation_date: ~D[2007-01-01],
          resignation_type: :resigned
        )

      attrs = %{
        org_id: org.id,
        admission_date: ~D[2009-01-01],
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: company.entity_id,
        work_at_id: company.entity_id
      }

      assert {:ok, return} = Create.call(org, individual, attrs)

      assert Repo.get_by(
               Registration,
               Enum.into(attrs, %{
                 id: return.id,
                 org_id: org.id,
                 individual_id: individual.entity_id
               })
             )
    end

    test "returns changeset errors" do
      org = insert(:org)
      individual = insert(:individual, org: org)

      assert {:error, changeset} = Create.call(org, individual, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               admission_date: ["can't be blank"],
               position_id: ["can't be blank"],
               registered_at_id: ["can't be blank"],
               sector_id: ["can't be blank"],
               work_at_id: ["can't be blank"]
             }
    end

    test "company doesn't exist" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: UUID.generate(),
        work_at_id: UUID.generate()
      }

      assert Create.call(org, individual, attrs) == {:error, "empresa não encontrada"}
    end

    test "virtual company" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      company = insert(:virtual_company, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: company.entity_id,
        work_at_id: company.entity_id
      }

      assert Create.call(org, individual, attrs) == {:error, "empresa virtual"}
    end

    test "admission date before last resignation date of the same company" do
      org = insert(:org)
      company = insert(:company, org: org)
      individual = insert(:individual, org: org)

      _before_last_registration =
        insert(:employee_registration,
          org: org,
          individual: individual,
          registered_at: company,
          admission_date: ~D[2008-01-01],
          resignation_date: ~D[2009-01-01],
          resignation_type: :resigned
        )

      _last_registration =
        insert(:employee_registration,
          org: org,
          individual: individual,
          registered_at: company,
          admission_date: ~D[2010-01-01],
          resignation_date: ~D[2012-01-01],
          resignation_type: :resigned
        )

      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: ~D[2011-01-01],
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: company.entity_id,
        work_at_id: company.entity_id
      }

      assert Create.call(org, individual, attrs) ==
               {:error, "data de contratação anterior a última data de desligamento"}
    end
  end
end
