defmodule Sig.HR.RegistrationsTest do
  use Sig.DataCase

  alias Sig.Entities.Companies.Company
  alias Sig.HR.Registrations
  alias Sig.HR.Registrations.Salaries.Salary
  alias Sig.HR.Registrations.Registration

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Registration{}} = Registrations.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Registration{}} =
               Registrations.update_change(%Registration{}, %{})

      assert %Ecto.Changeset{data: %Registration{}} = Registrations.update_change(%Registration{})
    end
  end

  describe "resignation_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Registration{}} =
               Registrations.resignation_change(%Registration{}, %{})

      assert %Ecto.Changeset{data: %Registration{}} =
               Registrations.resignation_change(%Registration{})
    end
  end

  describe "update/2" do
    test "updates a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      company = insert(:company, org: org)

      attrs = %{
        sector_id: sector.id,
        position_id: position.id,
        work_at_id: company.entity_id
      }

      assert {:ok, return} = Registrations.update(registration, attrs)

      assert Repo.get_by(
               Registration,
               Enum.into(attrs, %{
                 id: return.id,
                 org_id: org.id,
                 individual_id: registration.individual_id
               })
             )
    end

    test "work at company belongs to another org" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)

      other_org_company = insert(:company)

      attrs = %{
        sector_id: sector.id,
        position_id: position.id,
        work_at_id: other_org_company.entity_id
      }

      assert {:error, changeset} = Registrations.update(registration, attrs)

      assert errors_on(changeset) == %{work_at: ["does not exist"]}
    end

    test "returns changeset errors" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        sector_id: :invalid,
        position_id: :invalid,
        work_at_id: :invalid
      }

      assert {:error, changeset} = Registrations.update(registration, attrs)

      assert errors_on(changeset) == %{
               position_id: ["is invalid"],
               sector_id: ["is invalid"],
               work_at_id: ["is invalid"]
             }
    end
  end

  describe "list_by_individual/1" do
    test "lists registrations by individual ordered by admission_date" do
      org = insert(:org)
      individual = insert(:individual, org: org)

      %{id: registration_1_id} =
        insert(:employee_registration,
          org: org,
          individual: individual,
          admission_date: ~D[2010-01-01]
        )

      %{id: registration_2_id} =
        insert(:employee_registration,
          org: org,
          individual: individual,
          admission_date: ~D[2012-01-01]
        )

      _to_ignore_1 = insert(:employee_registration, org: org)
      _to_ignore_2 = insert(:employee_registration)

      assert [
               %Registration{id: ^registration_1_id},
               %Registration{id: ^registration_2_id}
             ] = Registrations.list_by_individual(individual)
    end

    test "preloads" do
      org = insert(:org)
      individual = insert(:individual, org: org)

      registration_1 =
        insert(:employee_registration,
          org: org,
          individual: individual,
          admission_date: ~D[2010-01-01]
        )

      registration_2 =
        insert(:employee_registration,
          org: org,
          individual: individual,
          admission_date: ~D[2012-01-01]
        )

      insert_list(2, :employee_salary, org: org, registration: registration_1)
      insert(:employee_salary, org: org, registration: registration_2)

      assert [
               %Registration{
                 registered_at: %Company{},
                 work_at: %Company{},
                 salaries: [%Salary{}, %Salary{}]
               },
               %Registration{
                 registered_at: %Company{},
                 work_at: %Company{},
                 salaries: [%Salary{}]
               }
             ] = Registrations.list_by_individual(individual)
    end

    test "fills salary_amount virtual field with the latest salary amount" do
      org = insert(:org)
      individual = insert(:individual, org: org)

      registration_1 =
        insert(:employee_registration,
          org: org,
          individual: individual,
          admission_date: ~D[2010-01-01]
        )

      registration_2 =
        insert(:employee_registration,
          org: org,
          individual: individual,
          admission_date: ~D[2012-01-01]
        )

      insert(:employee_salary,
        org: org,
        registration: registration_1,
        start_date: ~D[2010-01-01],
        amount: 1_500_00
      )

      insert(:employee_salary,
        org: org,
        registration: registration_1,
        start_date: ~D[2010-06-01],
        amount: 1_700_00
      )

      insert(:employee_salary,
        org: org,
        registration: registration_2,
        start_date: ~D[2012-01-01],
        amount: 1_600_00
      )

      insert(:employee_salary,
        org: org,
        registration: registration_2,
        start_date: ~D[2012-08-01],
        amount: 1_800_00
      )

      assert [
               %Registration{salary_amount: %Money{amount: 1_700_00, currency: :BRL}},
               %Registration{salary_amount: %Money{amount: 1_800_00, currency: :BRL}}
             ] = Registrations.list_by_individual(individual)
    end

    test "individual has no registration" do
      individual = insert(:individual)

      assert Registrations.list_by_individual(individual) == []
    end
  end

  describe "fetch/2" do
    test "fetches a registration" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)

      assert %Registration{} = Registrations.get(individual, registration.id)
    end

    test "preloads" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)
      insert_list(2, :employee_salary, org: org, registration: registration)

      assert %Registration{salaries: [%Salary{}, %Salary{}]} = Registrations.get(individual, registration.id)
    end

    test "registration from other individual" do
      org = insert(:org)
      individual_1 = insert(:individual, org: org)
      individual_2 = insert(:individual, org: org)

      registration = insert(:employee_registration, org: org, individual: individual_1)

      assert Registrations.get(individual_2, registration.id) == nil
    end

    test "registration doesn't exist" do
      individual = insert(:individual)

      assert Registrations.get(individual, UUID.generate()) == nil
    end
  end

  describe "subscribe_to_individual_registrations/1" do
    test "subscribes to individual registrations topic" do
      individual = insert(:individual)
      topic = "individual_id:" <> individual.entity_id <> ":registrations"

      assert Registrations.subscribe_to_individual_registrations(individual) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_individual_registrations, :registrations}
      )

      assert_receive {:updated_individual_registrations, :registrations}
    end
  end

  describe "broadcast_individual_registrations/1" do
    test "broadcasts registrations from an individual" do
      org = insert(:org)
      individual = insert(:individual, org: org)

      _right_registrations =
        insert_list(2, :employee_registration, org: org, individual: individual)

      _wrong_registrations = insert_list(2, :employee_registration)

      topic = "individual_id:" <> individual.entity_id <> ":registrations"

      @endpoint.subscribe(topic)

      assert Registrations.broadcast_individual_registrations(individual) == :ok

      assert_receive {:updated_individual_registrations, received_registrations}

      assert Enum.count(received_registrations) == 2

      Enum.each(received_registrations, fn registration ->
        assert registration.org_id == org.id
        assert registration.individual_id == individual.entity_id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
