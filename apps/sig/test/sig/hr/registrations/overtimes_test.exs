defmodule Sig.HR.Registrations.OvertimesTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.Overtimes
  alias Sig.HR.Registrations.Overtimes.Overtime

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Overtime{}} = Overtimes.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Overtime{}} = Overtimes.update_change(%Overtime{}, %{})
      assert %Ecto.Changeset{data: %Overtime{}} = Overtimes.update_change(%Overtime{})
    end
  end

  describe "assign_payslip_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Overtime{}} =
               Overtimes.assign_payslip_change(%Overtime{}, %{})

      assert %Ecto.Changeset{data: %Overtime{}} = Overtimes.assign_payslip_change(%Overtime{})
    end
  end

  describe "create/2" do
    test "creates an overtime" do
      date = ~D[2021-01-01]
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: date)

      attrs = %{
        date: date,
        hours_amount: "01:00"
      }

      assert {:ok, %Overtime{id: id}} = Overtimes.create(registration, attrs)

      assert Repo.get_by(Overtime,
               org_id: org.id,
               id: id,
               date: attrs[:date],
               hours_amount: attrs[:hours_amount],
               registration_id: registration.id
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)
      assert {:error, changeset} = Overtimes.create(registration, %{})

      assert errors_on(changeset) == %{date: ["can't be blank"]}
    end

    test "when date is before regsitration admission_date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-01-01])

      attrs = %{
        date: ~D[2020-12-01],
        hours_amount: "01:00"
      }

      assert {:error, changeset} = Overtimes.create(registration, attrs)

      assert errors_on(changeset) == %{
               date: ["must be equal to or after registration admission_date"]
             }
    end
  end

  describe "update/2" do
    test "updates an overtime" do
      %{id: id} =
        overtime = insert(:employee_overtime, date: ~D[2021-01-01], hours_amount: "02:00")

      attrs = %{
        date: ~D[2021-02-01],
        hours_amount: "100:00"
      }

      assert {:ok, %Overtime{id: ^id}} = Overtimes.update(overtime, attrs)

      assert Repo.get_by(Overtime,
               org_id: overtime.org_id,
               id: overtime.id,
               date: attrs[:date],
               hours_amount: attrs[:hours_amount],
               registration_id: overtime.registration_id
             )
    end

    test "when overtime is assigned to a payslip" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      payslip = insert(:payslip, org: org, registration: registration)

      overtime =
        insert(:employee_overtime,
          org: org,
          registration: registration,
          payslip: payslip,
          date: ~D[2021-01-01],
          hours_amount: "02:00"
        )

      attrs = %{
        date: ~D[2021-02-01],
        hours_amount: "100:00"
      }

      assert Overtimes.update(overtime, attrs) ==
               {:error, "can't update an overtime with an assigned payslip"}

      assert Repo.get_by(Overtime,
               org_id: overtime.org_id,
               id: overtime.id,
               date: overtime.date,
               hours_amount: overtime.hours_amount,
               registration_id: overtime.registration_id
             )
    end

    test "returns changeset errors" do
      overtime = insert(:employee_overtime, date: ~D[2021-01-01], hours_amount: "02:00")

      attrs = %{
        date: nil,
        hours_amount: nil
      }

      assert {:error, changeset} = Overtimes.update(overtime, attrs)

      assert errors_on(changeset) == %{
               date: ["can't be blank"],
               hours_amount: ["can't be blank"]
             }
    end
  end

  describe "assign_payslip/2" do
    test "assigns a payslip to an overtime" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      %{id: id} = overtime = insert(:employee_overtime, org: org, registration: registration)
      payslip = insert(:payslip, org: org, registration: registration)

      assert {:ok, %Overtime{id: ^id}} =
               Overtimes.assign_payslip(overtime, %{payslip_id: payslip.id})

      assert Repo.get_by(Overtime, org_id: org.id, id: id, payslip_id: payslip.id)
    end

    test "returns changeset errors" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      overtime = insert(:employee_overtime, org: org, registration: registration)
      payslip = insert(:payslip, org: org)

      assert {:error, changeset} = Overtimes.assign_payslip(overtime, %{payslip_id: payslip.id})

      assert errors_on(changeset) == %{payslip_id: ["must belong to the same registration"]}
    end
  end

  describe "drop_payslip/2" do
    test "drops a payslip from an overtime" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      payslip = insert(:payslip, org: org, registration: registration)

      %{id: id} =
        overtime =
        insert(:employee_overtime, org: org, registration: registration, payslip: payslip)

      assert {:ok, %Overtime{id: ^id}} = Overtimes.drop_payslip(overtime)

      assert updated_overtime = Repo.get_by(Overtime, org_id: org.id, id: id)

      assert updated_overtime.payslip_id == nil
    end
  end

  describe "list_by_regitration/1" do
    test "lists ovetimes by registrations ordered by date" do
      org = insert(:org)
      %{id: registration_id} = registration = insert(:employee_registration, org: org)

      insert(:employee_overtime, org: org, registration: registration, date: ~D[2021-02-01])
      insert(:employee_overtime, org: org, registration: registration, date: ~D[2021-01-01])

      _to_ignore = insert(:employee_overtime, org: org)

      assert [
               %Overtime{registration_id: ^registration_id, date: ~D[2021-01-01]},
               %Overtime{registration_id: ^registration_id, date: ~D[2021-02-01]}
             ] = Overtimes.list_by_registration(registration)
    end

    test "when there is no overtime" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _to_ignore = insert(:employee_overtime, org: org)

      assert Overtimes.list_by_registration(registration) == []
    end
  end

  describe "list_by_payslip/1" do
    test "lists ovetimes by payslip ordered by date" do
      org = insert(:org)
      date = ~D[2021-01-01]
      registration = insert(:employee_registration, org: org, admission_date: date)

      %{id: payslip_id} =
        payslip = insert(:payslip, org: org, registration: registration, start_date: date)

      insert(:employee_overtime,
        org: org,
        registration: registration,
        payslip: payslip,
        date: ~D[2021-02-01]
      )

      insert(:employee_overtime,
        org: org,
        registration: registration,
        payslip: payslip,
        date: ~D[2021-01-01]
      )

      _to_ignore = insert(:employee_overtime, org: org, registration: registration)

      assert [
               %Overtime{payslip_id: ^payslip_id, date: ~D[2021-01-01]},
               %Overtime{payslip_id: ^payslip_id, date: ~D[2021-02-01]}
             ] = Overtimes.list_by_payslip(payslip)
    end

    test "when there is no overtime" do
      org = insert(:org)
      date = ~D[2021-01-01]
      registration = insert(:employee_registration, org: org, admission_date: date)
      payslip = insert(:payslip, org: org, registration: registration, start_date: date)

      _to_ignore = insert(:employee_overtime, org: org, registration: registration)

      assert Overtimes.list_by_payslip(payslip) == []
    end
  end

  describe "get/2" do
    test "gets an overtime by registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: id} =
        insert(:employee_overtime, org: org, registration: registration, date: ~D[2021-02-01])

      assert %Overtime{id: ^id} = Overtimes.get(registration, id)
    end

    test "when overtime belongs o another registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      overtime =
        insert(:employee_overtime, org: org, registration: registration, date: ~D[2021-02-01])

      another_regitration = insert(:employee_registration, org: org)

      assert Overtimes.get(another_regitration, overtime.id) == nil
    end
  end

  describe "delete/1" do
    test "deletes an overtime" do
      %{id: id} = overtime = insert(:employee_overtime)

      assert {:ok, %Overtime{id: ^id}} = Overtimes.delete(overtime)

      refute Repo.get_by(Overtime, org_id: overtime.org_id, id: id)
    end

    test "when overtime is assigned to a payslip" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      payslip = insert(:payslip, org: org, registration: registration)

      overtime =
        insert(:employee_overtime, org: org, registration: registration, payslip: payslip)

      assert Overtimes.delete(overtime) ==
               {:error, "can't delete an overtime with an assigned payslip"}

      assert Repo.get_by(Overtime,
               org_id: overtime.org_id,
               id: overtime.id,
               date: overtime.date,
               hours_amount: overtime.hours_amount,
               registration_id: overtime.registration_id
             )
    end
  end

  describe "subscribe_to_registration_overtimes/1" do
    test "subscribes to registration overtimes topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":overtimes"

      assert Overtimes.subscribe_to_registration_overtimes(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_overtimes, :overtimes}
      )

      assert_receive {:updated_registration_overtimes, :overtimes}
    end
  end

  describe "broadcast_registration_overtimes/1" do
    test "broadcasts overtimes from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_overtime, org: org, registration: registration, date: ~D[2021-02-01])
      insert(:employee_overtime, org: org, registration: registration, date: ~D[2021-01-01])

      _to_ignore = insert(:employee_overtime, org: org)

      topic = "registration_id:" <> registration.id <> ":overtimes"

      @endpoint.subscribe(topic)

      assert Overtimes.broadcast_registration_overtimes(registration) == :ok

      assert_receive {:updated_registration_overtimes, received_overtimes}

      assert Enum.count(received_overtimes) == 2

      Enum.each(received_overtimes, fn overtime ->
        assert overtime.org_id == org.id
        assert overtime.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
