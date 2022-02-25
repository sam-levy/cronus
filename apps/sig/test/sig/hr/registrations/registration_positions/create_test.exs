defmodule Sig.HR.Registrations.RegistrationPositions.CreateTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.RegistrationPositions.RegistrationPosition
  alias Sig.HR.Registrations.RegistrationPositions.Create

  describe "call/3" do
    test "creates a registration position" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      attrs = %{
        position_id: position.id,
        start_date: registration.admission_date
      }

      assert {:ok, %RegistrationPosition{id: id}} = Create.call(registration, attrs)

      assert Repo.get_by(RegistrationPosition,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               position_id: attrs[:position_id],
               start_date: attrs[:start_date]
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Create.call(registration, %{})

      assert errors_on(changeset) == %{
               position_id: ["can't be blank"],
               start_date: ["can't be blank"]
             }
    end

    test "same start date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      insert(:registration_position,
        org: org,
        registration: registration,
        position: position,
        start_date: ~D[2020-01-01]
      )

      insert(:registration_position,
        org: org,
        registration: registration,
        position: position,
        start_date: ~D[2021-01-01]
      )

      attrs = %{
        position_id: position.id,
        start_date: ~D[2021-01-01]
      }

      assert Create.call(registration, attrs) ==
               {:error, "a data de início deve ser posterior a data de início da última posição"}
    end

    test "inferior start date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      insert(:registration_position,
        org: org,
        registration: registration,
        position: position,
        start_date: ~D[2021-01-01]
      )

      attrs = %{
        position_id: position.id,
        start_date: ~D[2020-02-02]
      }

      assert Create.call(registration, attrs) ==
               {:error, "a data de início deve ser posterior a data de início da última posição"}
    end
  end
end
