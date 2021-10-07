defmodule Sig.HR.Registrations.CreateTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Create
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Salaries.Salary

  describe "call/3" do
    test "creates a registration and salary" do
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

      salary_amount = Enum.random(1_200_00..4_000_00)

      attrs = %{
        org_id: org.id,
        admission_date: ~D[2009-01-01],
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: company.entity_id,
        work_at_id: company.entity_id,
        salary_amount: salary_amount
      }

      assert {:ok, %Registration{} = registration} = Create.call(org, individual, attrs)

      get_by =
        attrs
        |> Map.drop([:salary_amount])
        |> Enum.into(%{
          id: registration.id,
          org_id: org.id,
          individual_id: individual.entity_id
        })

      assert Repo.get_by(Registration, get_by)

      assert Repo.get_by(Salary,
               org_id: org.id,
               registration_id: registration.id,
               amount: salary_amount,
               start_date: registration.admission_date
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
               salary_amount: ["can't be blank"]
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
        work_at_id: UUID.generate(),
        salary_amount: Enum.random(1_200_00..4_000_00)
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
        work_at_id: company.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
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
        admission_date: ~D[2011-02-02],
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: company.entity_id,
        work_at_id: company.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert Create.call(org, individual, attrs) ==
               {:error, "a data de contratação deve ser posterior a última data de desligamento"}
    end

    test "last registration still on going" do
      org = insert(:org)
      company_1 = insert(:company, org: org)
      company_2 = insert(:company, org: org)
      individual = insert(:individual, org: org)

      _last_registration =
        insert(:employee_registration,
          org: org,
          individual: individual,
          registered_at: company_1,
          admission_date: ~D[2010-01-01],
        )

        sector = insert(:org_sector, org: org)
        position = insert(:org_position, org: org)

        attrs = %{
          org_id: org.id,
          admission_date: ~D[2011-02-02],
          sector_id: sector.id,
          position_id: position.id,
          individual_id: individual.entity_id,
          registered_at_id: company_2.entity_id,
          salary_amount: 1_200_00
        }

        assert {:ok, %Registration{}} = Create.call(org, individual, attrs)
    end
  end
end
