defmodule Sig.HR.Registrations.Overtimes.OvertimeTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.Overtimes.Overtime

  describe "employee_salaries table constraints" do
    test "org_id not_null_violation" do
      date = ~D[2021-01-01]

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: date)
      payslip = insert(:payslip, org: org, registration: registration, start_date: date)

      overtime = %Overtime{
        date: date,
        hours_amount: "01:00",
        registration_id: registration.id,
        payslip_id: payslip.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_overtimes\" violates not-null constraint/,
                   fn -> Repo.insert!(overtime) end
    end

    test "org_id foreign_key_constraint" do
      date = ~D[2021-01-01]

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: date)
      payslip = insert(:payslip, org: org, registration: registration, start_date: date)

      overtime = %Overtime{
        org_id: UUID.generate(),
        date: date,
        hours_amount: "01:00",
        registration_id: registration.id,
        payslip_id: payslip.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_overtimes_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert!(overtime) end
    end

    test "registration_id not_null_violation" do
      date = ~D[2021-01-01]

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: date)
      payslip = insert(:payslip, org: org, registration: registration, start_date: date)

      overtime = %Overtime{
        org_id: org.id,
        date: date,
        hours_amount: "01:00",
        payslip_id: payslip.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_overtimes\" violates not-null constraint/,
                   fn -> Repo.insert!(overtime) end
    end

    test "registration_id foreign_key_constraint" do
      date = ~D[2021-01-01]

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: date)
      payslip = insert(:payslip, org: org, registration: registration, start_date: date)

      overtime = %Overtime{
        org_id: org.id,
        date: date,
        hours_amount: "01:00",
        registration_id: UUID.generate(),
        payslip_id: payslip.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_overtimes_registration_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert!(overtime) end
    end

    test "[:date, :registration_id, :org_id] unique_constraint" do
      date = ~D[2021-01-01]

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: date)

      _existing_overtime =
        insert(:employee_overtime, org: org, date: date, registration: registration)

      # Allow same date for different registration
      insert(:employee_overtime, org: org, date: date)

      overtime = %Overtime{
        org_id: org.id,
        date: date,
        hours_amount: "01:00",
        registration_id: registration.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_overtimes_date_registration_unique \(unique_constraint\)/,
                   fn -> Repo.insert!(overtime) end
    end

    test "employee_overtimes_date_beginning_of_month" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-01-01])

      overtime = %Overtime{
        org_id: org.id,
        date: ~D[2021-01-02],
        hours_amount: "01:00",
        registration_id: registration.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_overtimes_date_beginning_of_month \(check_constraint\)/,
                   fn -> Repo.insert(overtime) end
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        date: ~D[2021-01-01],
        hours_amount: "01:00",
        registration_id: UUID.generate(),
        payslip_id: UUID.generate()
      }

      assert changeset = Overtime.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               date: attrs[:date],
               hours_amount: attrs[:hours_amount],
               registration_id: attrs[:registration_id],
               payslip_id: attrs[:payslip_id]
             }
    end

    test "missing required attrs" do
      assert changeset = Overtime.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               date: ["can't be blank"],
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        date: :invalid,
        hours_amount: :invalid,
        registration_id: :invalid,
        payslip_id: :invalid
      }

      assert changeset = Overtime.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               date: ["is invalid"],
               hours_amount: ["is invalid"],
               registration_id: ["is invalid"],
               payslip_id: ["is invalid"]
             }
    end

    test "invalid hours_amount format" do
      attrs = %{
        org_id: UUID.generate(),
        date: ~D[2021-01-01],
        hours_amount: "01:61",
        registration_id: UUID.generate(),
        payslip_id: UUID.generate()
      }

      assert changeset = Overtime.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{hours_amount: ["has invalid format"]}
    end

    test "when date is not beginning of the month" do
      date = ~D[2021-01-01]

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: date)
      payslip = insert(:payslip, org: org, registration: registration, start_date: date)

      attrs = %{
        org_id: org.id,
        date: ~D[2021-01-02],
        hours_amount: "01:00",
        registration_id: registration.id,
        payslip_id: payslip.id
      }

      assert changeset = Overtime.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{date: ["must be first day of month"]}
    end

    test "date unique constraint" do
      date = ~D[2021-01-01]

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: date)

      insert(:employee_overtime, org: org, registration: registration, date: date, hours_amount: "02:00")

      attrs = %{
        org_id: org.id,
        date: date,
        hours_amount: "01:00",
        registration_id: registration.id
      }

      assert {:error, changeset} =
        attrs
        |> Overtime.create_changeset()
        |> Repo.insert()

      assert errors_on(changeset) == %{date: ["has already been taken"]}
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      overtime = insert(:employee_overtime, date: ~D[2021-01-01], hours_amount: "02:00")

      attrs = %{
        date: ~D[2021-02-01],
        hours_amount: "100:00"
      }

      assert changeset = Overtime.update_changeset(overtime, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               date: attrs[:date],
               hours_amount: attrs[:hours_amount]
             }
    end

    test "missing required attrs" do
      overtime = insert(:employee_overtime, date: ~D[2021-01-01], hours_amount: "02:00")

      attrs = %{date: nil, hours_amount: nil}

      assert changeset = Overtime.update_changeset(overtime, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               date: ["can't be blank"],
               hours_amount: ["can't be blank"]
             }
    end

    test "invalid hours_amount format" do
      overtime = insert(:employee_overtime, date: ~D[2021-01-01], hours_amount: "02:00")

      attrs = %{
        date: ~D[2021-02-01],
        hours_amount: "03: 00"
      }

      assert changeset = Overtime.update_changeset(overtime, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{hours_amount: ["has invalid format"]}
    end

    test "when date is not beginning of the month" do
      overtime = insert(:employee_overtime, date: ~D[2021-01-01])

      attrs = %{date: ~D[2021-01-02]}

      assert changeset = Overtime.update_changeset(overtime, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{date: ["must be first day of month"]}
    end

    test "date unique constraint" do
      date = ~D[2021-01-01]

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: date)

      _existing_overtime = insert(:employee_overtime, org: org, registration: registration, date: date, hours_amount: "02:00")

      overtime = insert(:employee_overtime, org: org, registration: registration, date: ~D[2021-02-01], hours_amount: "01:00")

      attrs = %{
        date: date,
        hours_amount: "03:00"
      }

      assert {:error, changeset} =
        overtime
        |> Overtime.update_changeset(attrs)
        |> Repo.update()

      assert errors_on(changeset) == %{date: ["has already been taken"]}
    end
  end

  describe "assign_payslip_changeset/2" do
    test "success" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      overtime = insert(:employee_overtime, org: org, registration: registration)
      payslip = insert(:payslip, org: org, registration: registration)

      assert changeset = Overtime.assign_payslip_changeset(overtime, %{payslip_id: payslip.id})

      assert changeset.valid?

      assert changeset.changes == %{payslip_id: payslip.id}
    end

    test "when payslip doesn't exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      overtime = insert(:employee_overtime, org: org, registration: registration)
      payslip = insert(:payslip, org: org, registration: registration)

      assert changeset = Overtime.assign_payslip_changeset(overtime, %{payslip_id: payslip.id})

      assert changeset.valid?

      assert changeset.changes == %{payslip_id: payslip.id}

      Repo.delete(payslip)

      assert {:error, changeset} = Repo.update(changeset)

      assert errors_on(changeset) == %{payslip: ["does not exist"]}
    end
  end

  describe "drop_payslip_changeset/1" do
    test "drops the payslip_id" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      payslip = insert(:payslip, org: org, registration: registration)

      overtime =
        insert(:employee_overtime, org: org, registration: registration, payslip: payslip)

      assert changeset = Overtime.drop_payslip_changeset(overtime)

      assert changeset.valid?

      assert changeset.changes == %{payslip_id: nil}
    end

    test "when overtime payslip_id is already nil" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      overtime = insert(:employee_overtime, org: org, registration: registration)

      assert changeset = Overtime.drop_payslip_changeset(overtime)

      assert changeset.valid?

      assert changeset.changes == %{}
    end
  end
end
