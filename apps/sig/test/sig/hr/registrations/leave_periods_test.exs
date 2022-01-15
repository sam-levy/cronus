defmodule Sig.HR.Registrations.LeavePeriodsTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.LeavePeriods
  alias Sig.HR.Registrations.LeavePeriods.LeavePeriod

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %LeavePeriod{}} = LeavePeriods.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %LeavePeriod{}} =
               LeavePeriods.update_change(%LeavePeriod{}, %{})

      assert %Ecto.Changeset{data: %LeavePeriod{}} = LeavePeriods.update_change(%LeavePeriod{})
    end
  end

  describe "list_leave_period_types/0" do
    test "lists leave period types" do
      assert LeavePeriods.list_leave_period_types() == ["maternity_leave", "medical_license"]
    end
  end

  describe "get/2" do
    test "gets a leave period" do
      registration = insert(:employee_registration)

      %{id: id} =
        insert(:employee_leave_period, org: registration.org, registration: registration)

      assert %LeavePeriod{id: ^id} = LeavePeriods.get(registration, id)
    end

    test "leave period from another registration" do
      org = insert(:org)
      registration_1 = insert(:employee_registration, org: org)
      registration_2 = insert(:employee_registration, org: org)

      leave_period = insert(:employee_leave_period, org: org, registration: registration_1)

      assert LeavePeriods.get(registration_2, leave_period.id) == nil
    end

    test "leave period doesn't exist" do
      registration = insert(:employee_registration)

      assert LeavePeriods.get(registration, UUID.generate()) == nil
    end
  end

  describe "list_by_registration/1" do
    test "lists leave periods by registration ordered by start_date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_leave_period,
        org: org,
        registration: registration,
        start_date: ~D[2020-01-01]
      )

      insert(:employee_leave_period,
        org: org,
        registration: registration,
        start_date: ~D[2020-06-01]
      )

      assert [
               %LeavePeriod{start_date: ~D[2020-01-01]},
               %LeavePeriod{start_date: ~D[2020-06-01]}
             ] = LeavePeriods.list_by_registration(registration)
    end

    test "registration has no leave period" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      assert LeavePeriods.list_by_registration(registration) == []
    end
  end

  describe "create/1" do
    test "creates a leave period when none exist" do
      registration = insert(:employee_registration)

      attrs = %{
        org_id: registration.org_id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(30)
      }

      assert {:ok, %LeavePeriod{id: id}} = LeavePeriods.create(registration, attrs)

      assert Repo.get_by(LeavePeriod,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               type: attrs[:type],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date]
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = LeavePeriods.create(registration, %{})

      assert errors_on(changeset) == %{
               type: ["can't be blank"],
               start_date: ["can't be blank"],
               end_date: ["can't be blank"]
             }
    end
  end

  describe "update/2" do
    test "updates a leave period" do
      leave_period =
        insert(:employee_leave_period,
          type: :maternity_leave,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      attrs = %{
        type: :medical_license,
        start_date: ~D[2021-01-02],
        end_date: ~D[2021-01-04]
      }

      assert {:ok, _return} = LeavePeriods.update(leave_period, attrs)

      assert Repo.get_by(LeavePeriod,
               id: leave_period.id,
               org_id: leave_period.org_id,
               registration_id: leave_period.registration_id,
               type: attrs[:type],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date]
             )
    end

    test "returns changeset errors" do
      leave_period =
        insert(:employee_leave_period,
          type: :maternity_leave,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      attrs = %{
        type: :invalid,
        start_date: :invalid,
        end_date: :invalid
      }

      assert {:error, changeset} = LeavePeriods.update(leave_period, attrs)

      assert errors_on(changeset) == %{
               type: ["is invalid"],
               start_date: ["is invalid"],
               end_date: ["is invalid"]
             }
    end
  end

  describe "subscribe_to_registration_leave_periods/1" do
    test "subscribes to registration leave_periods topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":leave_periods"

      assert LeavePeriods.subscribe_to_registration_leave_periods(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_leave_periods, :leave_periods}
      )

      assert_receive {:updated_registration_leave_periods, :leave_periods}
    end
  end

  describe "broadcast_registration_leave_periods/1" do
    test "broadcasts leave_periods from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_leave_period,
        org: org,
        registration: registration,
        start_date: ~D[2020-01-01],
        end_date: ~D[2020-02-01]
      )

      insert(:employee_leave_period,
        org: org,
        registration: registration,
        start_date: ~D[2020-03-01],
        end_date: ~D[2020-04-01]
      )

      insert(:employee_leave_period)

      topic = "registration_id:" <> registration.id <> ":leave_periods"

      @endpoint.subscribe(topic)

      assert LeavePeriods.broadcast_registration_leave_periods(registration) == :ok

      assert_receive {:updated_registration_leave_periods, received_leave_periods}

      assert Enum.count(received_leave_periods) == 2

      Enum.each(received_leave_periods, fn leave_period ->
        assert leave_period.org_id == org.id
        assert leave_period.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
