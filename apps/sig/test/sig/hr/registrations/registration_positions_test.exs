defmodule Sig.HR.Registrations.RegistrationPositionsTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.RegistrationPositions
  alias Sig.HR.Registrations.RegistrationPositions.RegistrationPosition

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %RegistrationPosition{}} =
               RegistrationPositions.create_change()
    end
  end

  describe "update_change/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %RegistrationPosition{}} =
               RegistrationPositions.update_change(%RegistrationPosition{}, %{})

      assert %Ecto.Changeset{data: %RegistrationPosition{}} =
               RegistrationPositions.update_change(%RegistrationPosition{})
    end
  end

  describe "update/2" do
    test "updates a salary" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-01-01])

      %{id: registration_position_id} =
        registration_position =
        insert(:registration_position, org: org, start_date: registration.admission_date)

      new_position = insert(:org_position, org: org)

      attrs = %{
        position_id: new_position.id,
        start_date: ~D[2021-02-01]
      }

      assert {:ok, %RegistrationPosition{id: ^registration_position_id}} =
               RegistrationPositions.update(registration_position, attrs)

      assert Repo.get_by(RegistrationPosition,
               org_id: org.id,
               id: registration_position_id,
               start_date: ~D[2021-02-01],
               position_id: new_position.id
             )
    end

    test "when `start_date` is before the registration `admission_date`" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-01-01])

      %{id: registration_position_id} =
        registration_position =
        insert(:registration_position, org: org, start_date: registration.admission_date)

      new_position = insert(:org_position, org: org)

      attrs = %{
        position_id: new_position.id,
        start_date: ~D[2020-12-01]
      }

      assert RegistrationPositions.update(registration_position, attrs) ==
               {:error, "A data inicial deve ser igual ou posterir a data de registro"}

      assert Repo.get_by(RegistrationPosition,
               org_id: org.id,
               id: registration_position_id,
               start_date: registration.admission_date,
               position_id: registration_position.position_id
             )
    end

    test "returns changeset errors" do
      org = insert(:org)
      org_position = insert(:org_position, org: org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-01-01])

      insert(:registration_position,
        org: org,
        registration: registration,
        position: org_position,
        start_date: registration.admission_date
      )

      registration_position_2 =
        insert(:registration_position,
          org: org,
          registration: registration,
          position: org_position,
          start_date: ~D[2021-02-01]
        )

      attrs = %{
        start_date: registration.admission_date
      }

      assert {:error, changeset} = RegistrationPositions.update(registration_position_2, attrs)

      assert errors_on(changeset) == %{
               start_date: ["has already been taken"]
             }

      assert Repo.get_by(RegistrationPosition,
               org_id: registration_position_2.org_id,
               id: registration_position_2.id,
               start_date: ~D[2021-02-01],
               position_id: registration_position_2.position_id
             )
    end
  end

  describe "delete/1" do
    test "deletes a registration position" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-01-01])

      registration_position_1 =
        insert(:registration_position,
          org: org,
          registration: registration,
          start_date: registration.admission_date
        )

      %{id: registration_position_2_id} =
        registration_position_2 =
        insert(:registration_position,
          org: org,
          registration: registration,
          start_date: Date.add(registration.admission_date, 10)
        )

      assert {:ok, %RegistrationPosition{id: ^registration_position_2_id}} =
               RegistrationPositions.delete(registration_position_2)

      refute Repo.get_by(RegistrationPosition, org_id: org.id, id: registration_position_2.id)

      assert Repo.get_by(RegistrationPosition, org_id: org.id, id: registration_position_1.id)
    end

    test "when registration has only one registration position" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-01-01])

      registration_position =
        insert(:registration_position,
          org: org,
          registration: registration,
          start_date: registration.admission_date
        )

      assert RegistrationPositions.delete(registration_position) ==
               {:error, "Deve existir pelo menos uma posição"}

      assert Repo.get_by(RegistrationPosition, org_id: org.id, id: registration_position.id)
    end
  end

  describe "list_by/1" do
    test "lists registration positions by registration ordered by start_date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-01-01])

      insert(:registration_position,
        org: org,
        registration: registration,
        start_date: ~D[2021-01-01]
      )

      insert(:registration_position,
        org: org,
        registration: registration,
        start_date: ~D[2021-02-01]
      )

      assert [
               %RegistrationPosition{start_date: ~D[2021-01-01]},
               %RegistrationPosition{start_date: ~D[2021-02-01]}
             ] = RegistrationPositions.list_by(registration)
    end
  end

  describe "get/2" do
    test "gets a registration position" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: registration_position_id} =
        insert(:registration_position,
          org: org,
          registration: registration,
          start_date: ~D[2021-01-01]
        )

      assert %RegistrationPosition{id: ^registration_position_id} =
               RegistrationPositions.get(registration, registration_position_id)
    end

    test "invalid id" do
      registration = insert(:employee_registration)

      assert RegistrationPositions.get(registration, UUID.generate()) == nil
    end
  end

  describe "fetch/2" do
    test "fetches a registration position" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: registration_position_id} =
        insert(:registration_position,
          org: org,
          registration: registration,
          start_date: ~D[2021-01-01]
        )

      assert {:ok, %RegistrationPosition{id: ^registration_position_id}} =
               RegistrationPositions.fetch(registration, registration_position_id)
    end

    test "invalid id" do
      registration = insert(:employee_registration)

      assert RegistrationPositions.fetch(registration, UUID.generate()) == {:error, :not_found}
    end
  end

  describe "subscribe_to_registration_positions/1" do
    test "subscribes to registration positions topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":registration_positions"

      assert RegistrationPositions.subscribe_to_registration_positions(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_positions, :registration_positions}
      )

      assert_receive {:updated_registration_positions, :registration_positions}
    end
  end

  describe "broadcast_updated_registration_positions/1" do
    test "broadcasts registration positions from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      # Right registration_positions
      insert(:registration_position,
        org: org,
        registration: registration,
        start_date: registration.admission_date
      )

      insert(:registration_position,
        org: org,
        registration: registration,
        start_date: Date.add(registration.admission_date, 180)
      )

      _wrong_registration_positions = insert_list(2, :registration_position)

      topic = "registration_id:" <> registration.id <> ":registration_positions"

      @endpoint.subscribe(topic)

      assert RegistrationPositions.broadcast_updated_registration_positions(registration) == :ok

      assert_receive {:updated_registration_positions, received_registration_positions}

      assert Enum.count(received_registration_positions) == 2

      Enum.each(received_registration_positions, fn registration_position ->
        assert registration_position.org_id == org.id
        assert registration_position.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
