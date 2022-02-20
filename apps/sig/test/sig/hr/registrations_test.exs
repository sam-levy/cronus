defmodule Sig.HR.RegistrationsTest do
  use Sig.DataCase, async: true

  alias Sig.Entities.Companies.Company
  alias Sig.HR.Registrations
  alias Sig.HR.Registrations.Salaries.Salary
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

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

      attrs = %{
        sector_id: sector.id,
        position_id: position.id
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

    test "returns changeset errors" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        sector_id: :invalid,
        position_id: :invalid
      }

      assert {:error, changeset} = Registrations.update(registration, attrs)

      assert errors_on(changeset) == %{
               position_id: ["is invalid"],
               sector_id: ["is invalid"]
             }
    end
  end

  describe "resign/2" do
    test "adds resignation fields to a registration without payslips" do
      org = insert(:org)

      %{id: registration_id} =
        registration = insert(:employee_registration, org: org, admission_date: ~D[2021-01-01])

      attrs = %{
        resignation_date: ~D[2022-01-01],
        resignation_type: :resigned
      }

      assert {:ok, %Registration{id: ^registration_id}} =
               Registrations.resign(registration, attrs)

      assert Repo.get_by(Registration,
               id: registration_id,
               org_id: org.id,
               admission_date: registration.admission_date,
               resignation_date: attrs.resignation_date,
               resignation_type: attrs.resignation_type
             )
    end

    test "when resgination is already resigned" do
      org = insert(:org)

      %{id: registration_id} =
        registration =
        insert(:employee_registration,
          org: org,
          admission_date: ~D[2021-01-01],
          resignation_date: ~D[2022-01-01],
          resignation_type: :resigned
        )

      attrs = %{
        resignation_date: ~D[2022-02-01],
        resignation_type: :dismissal
      }

      assert Registrations.resign(registration, attrs) == {:error, "Já foi desligado"}

      assert Repo.get_by(Registration,
               id: registration_id,
               org_id: org.id,
               admission_date: registration.admission_date,
               resignation_date: registration.resignation_date,
               resignation_type: registration.resignation_type
             )
    end

    test "when the `resignation_date` is before the last payslip `end_date`" do
      org = insert(:org)

      admission_date = ~D[2021-01-01]

      %{id: registration_id} =
        registration = insert(:employee_registration, org: org, admission_date: admission_date)

      insert(:payslip,
        org: org,
        registration: registration,
        start_date: admission_date,
        end_date: ~D[2021-01-31]
      )

      attrs = %{
        resignation_date: ~D[2021-01-25],
        resignation_type: :resigned
      }

      assert Registrations.resign(registration, attrs) ==
               {:error,
                "A data de desligamento deve ser igual ou posterior a data final do último holerite"}

      assert registration = Repo.get_by(Registration, org_id: org.id, id: registration_id)

      assert registration.resignation_date == nil
      assert registration.resignation_type == nil
    end
  end

  describe "undo_resignation/2" do
    test "nilify a registration resignation fields" do
      org = insert(:org)

      %{id: registration_id} =
        registration =
        insert(:employee_registration,
          org: org,
          admission_date: ~D[2021-01-01],
          resignation_date: ~D[2022-01-01],
          resignation_type: :resigned
        )

      assert {:ok, %Registration{id: ^registration_id}} =
               Registrations.undo_resignation(registration)

      assert registration =
               Repo.get_by(Registration,
                 id: registration_id,
                 org_id: org.id,
                 admission_date: registration.admission_date
               )

      assert registration.resignation_date == nil
      assert registration.resignation_type == nil
    end

    test "when registration resignation fields are already nil" do
      org = insert(:org)

      %{id: registration_id} =
        registration =
        insert(:employee_registration,
          org: org,
          admission_date: ~D[2021-01-01]
        )

      assert {:ok, %Registration{id: ^registration_id}} =
               Registrations.undo_resignation(registration)

      assert registration =
               Repo.get_by(Registration,
                 id: registration_id,
                 org_id: org.id,
                 admission_date: registration.admission_date
               )

      assert registration.resignation_date == nil
      assert registration.resignation_type == nil
    end
  end

  describe "list_by/1 Individual" do
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
             ] = Registrations.list_by(individual)
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

      insert(:employee_salary,
        org: org,
        registration: registration_1,
        start_date: registration_1.admission_date
      )

      insert(:employee_salary,
        org: org,
        registration: registration_1,
        start_date: Date.add(registration_1.admission_date, 180)
      )

      insert(:employee_salary, org: org, registration: registration_2)

      assert [
               %Registration{
                 registered_at: %Company{},
                 salaries: [%Salary{}, %Salary{}]
               },
               %Registration{
                 registered_at: %Company{},
                 salaries: [%Salary{}]
               }
             ] = Registrations.list_by(individual, preload: [:registered_at, :salaries])
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
             ] = Registrations.list_by(individual, preload: :salaries)
    end

    test "individual has no registration" do
      individual = insert(:individual)

      assert Registrations.list_by(individual) == []
    end
  end

  describe "list_by/1 Org" do
    test "lists registrations by org ordered by admission date" do
      org = insert(:org)

      insert(:employee_registration,
        org: org,
        admission_date: ~D[2012-01-01]
      )

      insert(:employee_registration,
        org: org,
        admission_date: ~D[2010-01-01]
      )

      insert(:employee_registration,
        org: org,
        admission_date: ~D[2009-01-01]
      )

      insert(:employee_registration,
        org: org,
        admission_date: ~D[2009-02-01],
        resignation_date: ~D[2010-06-01],
        resignation_type: :resigned
      )

      insert(:employee_registration,
        org: org,
        admission_date: ~D[2009-03-01],
        resignation_date: ~D[2009-06-01],
        resignation_type: :resigned
      )

      _to_ignore = insert(:employee_registration)

      assert [
               %Registration{admission_date: ~D[2009-01-01], resignation_date: nil},
               %Registration{admission_date: ~D[2009-02-01], resignation_date: ~D[2010-06-01]},
               %Registration{admission_date: ~D[2010-01-01], resignation_date: nil}
             ] =
               Registrations.list_by(org,
                 filter_by: [
                   active_in_period: [start_date: ~D[2010-01-01], end_date: ~D[2010-01-31]]
                 ]
               )
    end

    test "filter by sectors" do
      org = insert(:org)

      %{id: ktchen_sector_id} = kitchen_sector = insert(:org_sector, org: org, name: "kitchen")

      %{id: cleaning_sector_id} =
        cleaning_sector = insert(:org_sector, org: org, name: "cleaning")

      delivery_sector = insert(:org_sector, org: org, name: "delivery")

      insert(:employee_registration,
        org: org,
        admission_date: ~D[2012-01-01],
        sector: kitchen_sector
      )

      insert(:employee_registration,
        org: org,
        admission_date: ~D[2012-02-01],
        sector: cleaning_sector
      )

      insert(:employee_registration,
        org: org,
        admission_date: ~D[2012-03-01],
        sector: delivery_sector
      )

      assert [
               %Registration{sector_id: ^ktchen_sector_id},
               %Registration{sector_id: ^cleaning_sector_id}
             ] =
               Registrations.list_by(org,
                 filter_by: [
                   sector_id: [kitchen_sector.id, cleaning_sector.id],
                   active_in_period: [start_date: ~D[2020-01-01], end_date: ~D[2020-01-31]]
                 ]
               )
    end

    test "org has no registration" do
      org = insert(:org)

      assert Registrations.list_by(org,
               filter_by: [
                 active_in_period: [start_date: ~D[2010-01-01], end_date: ~D[2010-01-31]]
               ]
             ) == []
    end
  end

  describe "count_by/1" do
    test "count registrations by sector" do
      org = insert(:org)
      sector = insert(:org_sector, org: org)

      insert_list(2, :employee_registration, org: org, sector: sector)
      _to_ignore_1 = insert(:employee_registration, org: org)
      _to_ignore_2 = insert(:employee_registration)

      assert Registrations.count_by(sector) == 2
    end

    test "count registrations by position" do
      org = insert(:org)
      position = insert(:org_position, org: org)

      insert_list(2, :employee_registration, org: org, position: position)
      _to_ignore_1 = insert(:employee_registration, org: org)
      _to_ignore_2 = insert(:employee_registration)

      assert Registrations.count_by(position) == 2
    end
  end

  describe "get/2" do
    test "gets a registration from an individual" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      %{id: id} = insert(:employee_registration, org: org, individual: individual)

      assert %Registration{id: ^id} = Registrations.get(individual, id)
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

    test "gets a registration by org" do
      org = insert(:org)
      %{id: id} = insert(:employee_registration, org: org)

      assert %Registration{id: ^id} = Registrations.get(org, id)
    end

    test "registration from other org" do
      org_1 = insert(:org)
      org_2 = insert(:org)

      registration = insert(:employee_registration, org: org_1)

      assert Registrations.get(org_2, registration.id) == nil
    end

    test "preloads" do
      %{id: org_id} = org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: registration.admission_date
      )

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: Date.add(registration.admission_date, 100)
      )

      assert %Registration{salaries: [%Salary{}, %Salary{}], org: %Org{id: ^org_id}} =
               Registrations.get(individual, registration.id, preload: [:org, :salaries])
    end
  end

  describe "get_by/2" do
    test "returns a registration by attrs" do
      org = insert(:org)

      %{id: id} = insert(:employee_registration, org: org)

      assert %Registration{id: ^id, org: %Org{}} =
               Registrations.get_by([org_id: org.id, id: id], preload: :org)
    end

    test "when registration does't exist" do
      org = insert(:org)

      assert Registrations.get_by(org_id: org.id, id: UUID.generate()) == nil
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

  describe "broadcast_new_individual_registration/1" do
    test "broadcasts a new registration from an individual" do
      org = insert(:org)
      individual = insert(:individual, org: org)

      registration = insert(:employee_registration, org: org, individual: individual)

      topic = "individual_id:" <> individual.entity_id <> ":registrations"

      @endpoint.subscribe(topic)

      assert Registrations.broadcast_new_individual_registration(individual, registration) == :ok

      assert_receive {:new_individual_registration, received_registration}

      assert received_registration.org_id == org.id
      assert received_registration.individual_id == individual.entity_id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_updated_individual_registration/1" do
    test "broadcasts an updated registration from an individual" do
      org = insert(:org)
      individual = insert(:individual, org: org)

      registration = insert(:employee_registration, org: org, individual: individual)

      topic = "individual_id:" <> individual.entity_id <> ":registrations"

      @endpoint.subscribe(topic)

      assert Registrations.broadcast_updated_individual_registration(individual, registration) ==
               :ok

      assert_receive {:updated_individual_registration, received_registration}

      assert received_registration.org_id == org.id
      assert received_registration.individual_id == individual.entity_id

      @endpoint.unsubscribe(topic)
    end
  end
end
