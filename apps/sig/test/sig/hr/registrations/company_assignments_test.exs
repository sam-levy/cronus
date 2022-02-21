defmodule Sig.HR.Registrations.CompanyAssignmentsTest do
  use Sig.DataCase, async: true

  alias Sig.Entities.Companies.Company
  alias Sig.HR.Registrations.CompanyAssignments
  alias Sig.HR.Registrations.CompanyAssignments.CompanyAssignment

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %CompanyAssignment{}} = CompanyAssignments.create_change()
      assert %Ecto.Changeset{data: %CompanyAssignment{}} = CompanyAssignments.create_change(%{})
    end
  end

  describe "update_change/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %CompanyAssignment{}} =
               CompanyAssignments.update_change(%CompanyAssignment{}, %{})

      assert %Ecto.Changeset{data: %CompanyAssignment{}} =
               CompanyAssignments.update_change(%CompanyAssignment{})
    end
  end

  describe "update/2" do
    test "updates a company assignment" do
      start_date = ~D[2022-01-01]

      org = insert(:org)

      company_1 = insert(:company, org: org)
      company_2 = insert(:company, org: org)

      registration =
        insert(:employee_registration,
          org: org,
          registered_at: company_1,
          admission_date: start_date
        )

      %{id: assignment_id} =
        assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company_1,
          start_date: start_date
        )

      attrs = %{
        assigned_company_id: company_2.entity_id,
        start_date: ~D[2022-02-01]
      }

      assert {:ok, %CompanyAssignment{id: ^assignment_id}} =
               CompanyAssignments.update(assignment, attrs)

      assert Repo.get_by(CompanyAssignment,
               org_id: assignment.org_id,
               id: assignment_id,
               assigned_company_id: company_2.entity_id,
               start_date: ~D[2022-02-01]
             )
    end

    test "when `start_date` is before the registration `admission_date`" do
      start_date = ~D[2022-01-01]

      org = insert(:org)

      company_1 = insert(:company, org: org)
      company_2 = insert(:company, org: org)

      registration =
        insert(:employee_registration,
          org: org,
          registered_at: company_1,
          admission_date: start_date
        )

      %{id: assignment_id} =
        assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company_1,
          start_date: start_date
        )

      attrs = %{
        assigned_company_id: company_2.entity_id,
        start_date: ~D[2021-01-01]
      }

      assert CompanyAssignments.update(assignment, attrs) ==
               {:error, "A data inicial deve ser igual ou posterir a data de registro"}

      assert Repo.get_by(CompanyAssignment,
               org_id: assignment.org_id,
               id: assignment_id,
               assigned_company_id: company_1.entity_id,
               start_date: ~D[2022-01-01]
             )
    end

    test "returns changeset errors" do
      start_date = ~D[2022-01-01]

      org = insert(:org)

      company = insert(:company, org: org)

      registration =
        insert(:employee_registration,
          org: org,
          registered_at: company,
          admission_date: start_date
        )

      insert(:employee_company_assignment,
        org: org,
        registration: registration,
        assigned_company: company,
        start_date: start_date
      )

      %{id: assignment_id} =
        assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company,
          start_date: ~D[2022-02-01]
        )

      attrs = %{
        start_date: ~D[2022-01-01]
      }

      assert {:error, changeset} = CompanyAssignments.update(assignment, attrs)

      assert errors_on(changeset) == %{
               start_date: ["has already been taken"]
             }

      assert Repo.get_by(CompanyAssignment,
               org_id: assignment.org_id,
               id: assignment_id,
               assigned_company_id: company.entity_id,
               start_date: ~D[2022-02-01]
             )
    end
  end

  describe "create/2" do
    test "creates a company assignment" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      assigned_company = insert(:company, org: org)

      attrs = %{
        assigned_company_id: assigned_company.entity_id,
        start_date: ~D[2022-01-01]
      }

      assert {:ok, %CompanyAssignment{id: id}} = CompanyAssignments.create(registration, attrs)

      assert Repo.get_by(CompanyAssignment,
               id: id,
               org_id: org.id,
               registration_id: registration.id,
               assigned_company_id: attrs[:assigned_company_id],
               start_date: attrs[:start_date]
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = CompanyAssignments.create(registration, %{})

      assert errors_on(changeset) == %{
               assigned_company_id: ["can't be blank"],
               start_date: ["can't be blank"]
             }

      refute Repo.get_by(CompanyAssignment,
               org_id: registration.org_id,
               registration_id: registration.id
             )
    end
  end

  describe "delete/1" do
    test "deletes a company assignment" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: company_assignment_1_id} =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          start_date: registration.admission_date
        )

      %{id: company_assignment_2_id} =
        company_assignment_2 =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          start_date: Date.utc_today()
        )

      assert {:ok, %CompanyAssignment{id: ^company_assignment_2_id}} =
               CompanyAssignments.delete(company_assignment_2)

      refute Repo.get_by(CompanyAssignment, org_id: org.id, id: company_assignment_2_id)

      assert Repo.get_by(CompanyAssignment, org_id: org.id, id: company_assignment_1_id)
    end

    test "when registration has only one company assignment" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      company_assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          start_date: ~D[2021-06-01]
        )

      assert {:error, "Deve existir pelo menos uma designação"} =
               CompanyAssignments.delete(company_assignment)
    end
  end

  describe "list_by/3 `Registration`" do
    test "lists company assignment by registration ordered by `start_date`" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_company_assignment,
        org: org,
        registration: registration,
        start_date: ~D[2021-06-01]
      )

      insert(:employee_company_assignment,
        org: org,
        registration: registration,
        start_date: ~D[2021-01-01]
      )

      assert [
               %CompanyAssignment{start_date: ~D[2021-01-01]},
               %CompanyAssignment{start_date: ~D[2021-06-01]}
             ] = CompanyAssignments.list_by(registration)
    end

    test "default preloads" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_company_assignment, registration: registration, org: org)

      assert [
               %CompanyAssignment{assigned_company: %Company{}}
             ] = CompanyAssignments.list_by(registration)
    end
  end

  describe "get/3" do
    test "gets a company assignment" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: company_assignment_id} =
        insert(:employee_company_assignment, registration: registration, org: org)

      assert %CompanyAssignment{id: ^company_assignment_id, assigned_company: %Company{}} =
               CompanyAssignments.get(registration, company_assignment_id)
    end

    test "invalid id" do
      registration = insert(:employee_registration)

      assert CompanyAssignments.get(registration, UUID.generate()) == nil
    end
  end

  describe "fetch/2" do
    test "fetches a company assignment" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: company_assignment_id} =
        insert(:employee_company_assignment, registration: registration, org: org)

      assert {:ok, %CompanyAssignment{id: ^company_assignment_id, assigned_company: %Company{}}} =
               CompanyAssignments.fetch(registration, company_assignment_id)
    end

    test "invalid id" do
      registration = insert(:employee_registration)

      assert CompanyAssignments.fetch(registration, UUID.generate()) == {:error, :not_found}
    end
  end

  describe "subscribe_to_company_assignments/1" do
    test "subscribes to company assignments topic" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      topic =
        "org_id:" <>
          registration.org_id <> ":registration_id:" <> registration.id <> ":company_assignments"

      assert CompanyAssignments.subscribe_to_company_assignments(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_company_assignments, :company_assignments}
      )

      assert_receive {:updated_registration_company_assignments, :company_assignments}
    end
  end

  describe "broadcast_updated_company_assignments/1" do
    test "broadcasts company assignments from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _right_assignments =
        insert_list(2, :employee_company_assignment, org: org, registration: registration)

      _wrong_assignments = insert_list(2, :employee_company_assignment, org: org)

      topic =
        "org_id:" <>
          registration.org_id <> ":registration_id:" <> registration.id <> ":company_assignments"

      @endpoint.subscribe(topic)

      assert CompanyAssignments.broadcast_updated_company_assignments(registration) == :ok

      assert_receive {:updated_registration_company_assignments, received_assignments}

      assert Enum.count(received_assignments) == 2

      Enum.each(received_assignments, fn assignment ->
        assert assignment.org_id == org.id
        assert assignment.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
