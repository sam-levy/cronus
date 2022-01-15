defmodule Sig.HR.Registrations.LeavePeriods.LeavePeriodTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.LeavePeriods.LeavePeriod

  describe "employee_leave_periods table constraints" do
    test "org_id not_null_violation" do
      registration = insert(:employee_registration)

      leave_period = %LeavePeriod{
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(30)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_leave_periods\" violates not-null constraint/,
                   fn -> Repo.insert(leave_period) end
    end

    test "org_id foreign_key_constraint" do
      registration = insert(:employee_registration)

      leave_period = %LeavePeriod{
        org_id: UUID.generate(),
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(30)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_leave_periods_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(leave_period) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)

      leave_period = %LeavePeriod{
        org_id: org.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(30)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_leave_periods\" violates not-null constraint/,
                   fn -> Repo.insert(leave_period) end
    end

    test "registration_id foreign_key_constraint" do
      org = insert(:org)

      leave_period = %LeavePeriod{
        org_id: org.id,
        registration_id: UUID.generate(),
        type: random_enum_value(:employee_leave_period_type),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(30)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_leave_periods_registration_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(leave_period) end
    end

    test "employee_leave_periods_start_date_before_end_date constraint" do
      registration = insert(:employee_registration)

      leave_period = %LeavePeriod{
        org_id: registration.org_id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: ~D[2021-01-02],
        end_date: ~D[2021-01-01]
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_leave_periods_start_date_before_end_date \(check_constraint\)/,
                   fn -> Repo.insert(leave_period) end
    end

    test "start date cannot be before existing record end date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-02-01]
        )

      # Allow when there is no overlapping
      insert(:employee_leave_period,
        org: org,
        registration: registration,
        start_date: ~D[2019-12-01],
        end_date: ~D[2019-12-31]
      )

      # Allow overlapping for different registration
      insert(:employee_leave_period,
        org: org,
        start_date: ~D[2020-01-15],
        end_date: ~D[2020-02-15]
      )

      leave_period = %LeavePeriod{
        org_id: registration.org_id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: ~D[2020-01-15],
        end_date: ~D[2020-02-15]
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) start_date before or equal to an existing record end_date/,
                   fn -> Repo.insert(leave_period) end
    end

    test "end date cannot be after existing record start date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-02-01]
        )

      # Allow overlapping for different registration
      insert(:employee_leave_period,
        org: org,
        start_date: ~D[2019-12-15],
        end_date: ~D[2020-01-15]
      )

      leave_period = %LeavePeriod{
        org_id: registration.org_id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: ~D[2019-12-15],
        end_date: ~D[2020-01-15]
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) end_date after or equal to an existing record start_date/,
                   fn -> Repo.insert(leave_period) end
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: random_enum_value(:employee_leave_period_type),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(30)
      }

      assert changeset = LeavePeriod.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               type: attrs[:type],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date]
             }
    end

    test "missing required attrs" do
      assert changeset = LeavePeriod.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"],
               type: ["can't be blank"],
               start_date: ["can't be blank"],
               end_date: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        type: :invalid,
        start_date: :invalid,
        end_date: :invalid
      }

      assert changeset = LeavePeriod.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               registration_id: ["is invalid"],
               type: ["is invalid"],
               start_date: ["is invalid"],
               end_date: ["is invalid"]
             }
    end

    test "end date before start date" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: random_enum_value(:employee_leave_period_type),
        start_date: Date.utc_today(),
        end_date: Faker.Date.backward(1)
      }

      assert changeset = LeavePeriod.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["must be after start_date"]
             }
    end

    test "end date equal to start date" do
      date = Date.utc_today()

      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: random_enum_value(:employee_leave_period_type),
        start_date: date,
        end_date: date
      }

      assert changeset = LeavePeriod.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["must be after start_date"]
             }
    end

    test "start_date before the end_date of existing leave period" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-02-01]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: ~D[2020-01-15],
        end_date: ~D[2020-02-15]
      }

      assert {:error, changeset} =
               attrs
               |> LeavePeriod.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               start_date: ["cannot be before or equal to an existing record end_date"]
             }
    end

    test "start_date equal to the end_date of existing leave period" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-02-01]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: ~D[2021-01-01],
        end_date: ~D[2021-02-15]
      }

      assert {:error, changeset} =
               attrs
               |> LeavePeriod.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               start_date: ["cannot be before or equal to an existing record end_date"]
             }
    end

    test "end_date after the start_date of existing leave period" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-02-01]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: ~D[2019-12-15],
        end_date: ~D[2020-01-15]
      }

      assert {:error, changeset} =
               attrs
               |> LeavePeriod.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               end_date: ["cannot be after or equal to an existing record start_date"]
             }
    end

    test "end_date equal to the start_date of existing leave period" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: org,
          registration: registration,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-02-01]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: ~D[2020-12-01],
        end_date: ~D[2021-01-01]
      }

      assert {:error, changeset} =
               attrs
               |> LeavePeriod.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               end_date: ["cannot be after or equal to an existing record start_date"]
             }
    end

    test "when period doesn't overlap with existing leave period" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: org,
          registration: registration,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-02-01]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: ~D[2021-02-02],
        end_date: ~D[2021-03-02]
      }

      assert {:ok, _leave_period} =
               attrs
               |> LeavePeriod.create_changeset()
               |> Repo.insert()
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      leave_period =
        insert(:employee_leave_period,
          type: :maternity_leave,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-02-02]
        )

      attrs = %{
        type: :medical_license,
        start_date: ~D[2020-01-02],
        end_date: ~D[2020-02-03]
      }

      assert changeset = LeavePeriod.update_changeset(leave_period, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: attrs[:type],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date]
             }
    end

    test "invalid attrs types" do
      leave_period = insert(:employee_leave_period)

      attrs = %{
        type: :invalid,
        start_date: :invalid,
        end_date: :invalid
      }

      assert changeset = LeavePeriod.update_changeset(leave_period, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               type: ["is invalid"],
               start_date: ["is invalid"],
               end_date: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      leave_period =
        insert(:employee_leave_period,
          type: :maternity_leave,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-02-02]
        )

      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: :medical_license,
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(30)
      }

      assert changeset = LeavePeriod.update_changeset(leave_period, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: attrs[:type],
               end_date: attrs[:end_date],
               start_date: attrs[:start_date]
             }
    end

    test "end date before start date" do
      leave_period =
        insert(:employee_leave_period,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-02]
        )

      attrs = %{
        start_date: ~D[2020-01-02],
        end_date: ~D[2020-01-01]
      }

      assert changeset = LeavePeriod.update_changeset(leave_period, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["must be after start_date"]
             }
    end

    test "end date equal to start date" do
      leave_period =
        insert(:employee_leave_period,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-02]
        )

      attrs = %{
        start_date: ~D[2020-01-01],
        end_date: ~D[2020-01-01]
      }

      assert changeset = LeavePeriod.update_changeset(leave_period, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["must be after start_date"]
             }
    end

    test "start_date before the end_date of existing leave period" do
      registration = insert(:employee_registration)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-02-01]
        )

      leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          type: :maternity_leave,
          start_date: ~D[2020-03-01],
          end_date: ~D[2020-04-01]
        )

      attrs = %{
        start_date: ~D[2021-01-15],
        end_date: ~D[2021-02-15]
      }

      assert {:error, changeset} =
               leave_period
               |> LeavePeriod.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               start_date: ["cannot be before or equal to an existing record end_date"]
             }
    end

    test "start_date equal to the end_date of existing leave period" do
      registration = insert(:employee_registration)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-02-01]
        )

      leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          type: :maternity_leave,
          start_date: ~D[2020-03-01],
          end_date: ~D[2020-04-01]
        )

      attrs = %{
        start_date: ~D[2021-01-01],
        end_date: ~D[2021-02-15]
      }

      assert {:error, changeset} =
               leave_period
               |> LeavePeriod.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               start_date: ["cannot be before or equal to an existing record end_date"]
             }
    end

    test "end_date after the start_date of existing leave period" do
      registration = insert(:employee_registration)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-02-01]
        )

      leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          type: :maternity_leave,
          start_date: ~D[2020-03-01],
          end_date: ~D[2020-04-01]
        )

      attrs = %{
        start_date: ~D[2020-12-01],
        end_date: ~D[2021-01-02]
      }

      assert {:error, changeset} =
               leave_period
               |> LeavePeriod.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               end_date: ["cannot be after or equal to an existing record start_date"]
             }
    end

    test "end_date equal to the start_date of existing leave period" do
      registration = insert(:employee_registration)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-02-01]
        )

      leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          type: :maternity_leave,
          start_date: ~D[2020-03-01],
          end_date: ~D[2020-04-01]
        )

      attrs = %{
        start_date: ~D[2020-12-01],
        end_date: ~D[2021-01-01]
      }

      assert {:error, changeset} =
               leave_period
               |> LeavePeriod.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               end_date: ["cannot be after or equal to an existing record start_date"]
             }
    end

    test "when period doesn't overlap with existing leave period" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_leave_period =
        insert(:employee_leave_period,
          org: org,
          registration: registration,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-02-01]
        )

      leave_period =
        insert(:employee_leave_period,
          org: registration.org,
          registration: registration,
          type: :maternity_leave,
          start_date: ~D[2020-03-01],
          end_date: ~D[2020-04-01]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        type: random_enum_value(:employee_leave_period_type),
        start_date: ~D[2021-02-02],
        end_date: ~D[2021-03-02]
      }

      assert {:ok, _leave_period} =
               leave_period
               |> LeavePeriod.update_changeset(attrs)
               |> Repo.update()
    end
  end
end
