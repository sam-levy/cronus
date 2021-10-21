defmodule Sig.HR.Payslips.PayslipTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Payslip

  describe "payslips table constraints" do
    test "org_id not_null_violation" do
      registration = insert(:employee_registration)
      group = insert(:payslip_group, org: registration.org)

      payslip = %Payslip{
        amount: Enum.random(1_000_00..2_000_00),
        type: group.type,
        start_date: Date.utc_today() |> Date.beginning_of_month(),
        end_date: Date.utc_today() |> Date.end_of_month(),
        is_closed: false,
        group_id: group.id,
        registration_id: registration.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"payslips\" violates not-null constraint/,
                   fn -> Repo.insert(payslip) end
    end

    test "org_id foreign_key_constraint" do
      registration = insert(:employee_registration)
      group = insert(:payslip_group, org: registration.org)

      payslip = %Payslip{
        org_id: UUID.generate(),
        amount: Enum.random(1_000_00..2_000_00),
        type: group.type,
        start_date: Date.utc_today() |> Date.beginning_of_month(),
        end_date: Date.utc_today() |> Date.end_of_month(),
        is_closed: false,
        group_id: group.id,
        registration_id: registration.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslips_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(payslip) end
    end

    test "payslips_amount_positive constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org)

      payslip = %Payslip{
        org_id: org.id,
        amount: -1,
        type: group.type,
        start_date: Date.utc_today() |> Date.beginning_of_month(),
        end_date: Date.utc_today() |> Date.end_of_month(),
        is_closed: false,
        group_id: group.id,
        registration_id: registration.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslips_amount_positive \(check_constraint\)/,
                   fn -> Repo.insert(payslip) end
    end

    test "payslips_start_date_before_end_date constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org)

      payslip = %Payslip{
        org_id: org.id,
        amount: Enum.random(1_000_00..2_000_00),
        type: group.type,
        start_date: ~D[2020-01-01],
        end_date: ~D[2020-01-01],
        is_closed: false,
        group_id: group.id,
        registration_id: registration.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslips_start_date_before_end_date \(check_constraint\)/,
                   fn -> Repo.insert(payslip) end
    end

    test "start date cannot be before existing record end date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, date: ~D[2021-01-01])

      _existing_payslip =
        insert(:payslip,
          org: org,
          registration: registration,
          type: group.type,
          group: group,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-31]
        )

      # Allow when there is no overlap
      insert(:payslip,
        org: org,
        registration: registration,
        type: group.type,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28]
      )

      # Allow overlapping for different registration
      insert(:payslip,
        org: org,
        type: group.type,
        group: group,
        start_date: ~D[2021-01-15],
        end_date: ~D[2021-02-15]
      )

      payslip = %Payslip{
        org_id: org.id,
        amount: Enum.random(1_000_00..2_000_00),
        type: group.type,
        start_date: ~D[2021-01-15],
        end_date: ~D[2021-02-15],
        group_id: group.id,
        registration_id: registration.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) start_date before or equal to an existing record end_date/,
                   fn -> Repo.insert(payslip) end
    end

    test "end date cannot be after existing record start date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, date: ~D[2021-01-01])

      _existing_payslip =
        insert(:payslip,
          org: org,
          registration: registration,
          type: group.type,
          group: group,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-31]
        )

      # Allow overlapping for different registration
      insert(:payslip,
        org: org,
        group: group,
        start_date: ~D[2020-12-15],
        end_date: ~D[2021-01-15]
      )

      payslip = %Payslip{
        org_id: org.id,
        amount: Enum.random(1_000_00..2_000_00),
        type: group.type,
        start_date: ~D[2020-12-15],
        end_date: ~D[2021-01-15],
        group_id: group.id,
        registration_id: registration.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) end_date after or equal to an existing record start_date/,
                   fn -> Repo.insert(payslip) end
    end

    test "insert" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org)

      payslip = %Payslip{
        org_id: org.id,
        amount: Enum.random(1_000_00..2_000_00),
        type: group.type,
        start_date: Date.utc_today() |> Date.beginning_of_month(),
        end_date: Date.utc_today() |> Date.end_of_month(),
        is_closed: true,
        group_id: group.id,
        registration_id: registration.id
      }

      assert {:ok, _return} = Repo.insert(payslip)
    end

    test "default values" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org)

      payslip = %Payslip{
        org_id: org.id,
        type: group.type,
        start_date: Date.utc_today() |> Date.beginning_of_month(),
        end_date: Date.utc_today() |> Date.end_of_month(),
        group_id: group.id,
        registration_id: registration.id
      }

      assert {:ok, %{id: id}} = Repo.insert(payslip)

      assert Repo.get_by(Payslip, org_id: org.id, id: id, is_closed: false, amount: 0)
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(:payslip_group_type),
        start_date: Date.utc_today() |> Date.beginning_of_month(),
        end_date: Date.utc_today() |> Date.end_of_month(),
        registration_id: UUID.generate()
      }

      assert changeset = Payslip.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: attrs[:type],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date],
               registration_id: attrs[:registration_id]
             }
    end

    test "missing required attrs" do
      assert changeset = Payslip.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["can't be blank"],
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"],
               start_date: ["can't be blank"],
               type: ["can't be blank"]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        type: :invalid,
        start_date: :invalid,
        end_date: :invalid,
        registration_id: :invalid
      }

      assert changeset = Payslip.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["is invalid"],
               org_id: ["is invalid"],
               registration_id: ["is invalid"],
               start_date: ["is invalid"],
               type: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(:payslip_group_type),
        start_date: Date.utc_today() |> Date.beginning_of_month(),
        end_date: Date.utc_today() |> Date.end_of_month(),
        group_id: UUID.generate(),
        is_closed: true,
        registration_id: UUID.generate(),
        amount: Enum.random(1_000_00..2_000_00)
      }

      assert changeset = Payslip.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: attrs[:type],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date],
               registration_id: attrs[:registration_id]
             }
    end

    test "end_date before start_date" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(:payslip_group_type),
        start_date: ~D[2020-01-01],
        end_date: ~D[2019-12-31],
        registration_id: UUID.generate()
      }

      assert changeset = Payslip.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["must be after start_date"]
             }
    end

    test "end_date equal to start_date" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(:payslip_group_type),
        start_date: ~D[2020-01-01],
        end_date: ~D[2020-01-01],
        registration_id: UUID.generate()
      }

      assert changeset = Payslip.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["must be after start_date"]
             }
    end

    test "start date cannot be before existing record end date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, date: ~D[2021-01-01])

      _existing_payslip =
        insert(:payslip,
          org: org,
          registration: registration,
          type: group.type,
          group: group,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-31]
        )

      attrs = %{
        org_id: org.id,
        amount: Enum.random(1_000_00..2_000_00),
        type: group.type,
        start_date: ~D[2021-01-15],
        end_date: ~D[2021-02-15],
        registration_id: registration.id
      }

      assert {:error, changeset} =
               attrs
               |> Payslip.create_changeset()
               |> put_change(:group_id, group.id)
               |> Repo.insert()

      assert errors_on(changeset) == %{
               start_date: ["cannot be before or equal to an existing record end_date"]
             }
    end

    test "end date cannot be after existing record start date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, date: ~D[2021-01-01])

      _existing_payslip =
        insert(:payslip,
          org: org,
          registration: registration,
          type: group.type,
          group: group,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-31]
        )

      attrs = %{
        org_id: org.id,
        amount: Enum.random(1_000_00..2_000_00),
        type: group.type,
        start_date: ~D[2020-12-15],
        end_date: ~D[2021-01-15],
        registration_id: registration.id
      }

      assert {:error, changeset} =
               attrs
               |> Payslip.create_changeset()
               |> put_change(:group_id, group.id)
               |> Repo.insert()

      assert errors_on(changeset) == %{
               end_date: ["cannot be after or equal to an existing record start_date"]
             }
    end

    test "success" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, date: ~D[2021-02-01])

      _existing_payslip =
        insert(:payslip,
          org: org,
          registration: registration,
          type: :regular,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-31]
        )

      attrs = %{
        org_id: org.id,
        amount: Enum.random(1_000_00..2_000_00),
        type: group.type,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28],
        registration_id: registration.id
      }

      assert {:ok, _return} =
               attrs
               |> Payslip.create_changeset()
               |> put_change(:group_id, group.id)
               |> Repo.insert()
    end
  end

  describe "update_amount_changeset/2" do
    test "valid attrs" do
      payslip = insert(:payslip, amount: 1_000_00)
      attrs = %{amount: 1_100_00}

      assert changeset = Payslip.update_amount_changeset(payslip, attrs)

      assert changeset.valid?
      assert changeset.changes == %{amount: %Money{amount: attrs[:amount], currency: :BRL}}
    end

    test "ignores non permitted attrs" do
      payslip = insert(:payslip, amount: 1_000_00)

      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(:payslip_group_type),
        start_date: Date.utc_today() |> Date.beginning_of_month(),
        end_date: Date.utc_today() |> Date.end_of_month(),
        is_closed: true,
        group_id: UUID.generate(),
        registration_id: UUID.generate(),
        amount: 1_100_00
      }

      assert changeset = Payslip.update_amount_changeset(payslip, attrs)

      assert changeset.valid?
      assert changeset.changes == %{amount: %Money{amount: attrs[:amount], currency: :BRL}}
    end

    test "invalid attrs" do
      payslip = insert(:payslip, amount: 1_000_00)
      attrs = %{amount: :invalid}

      assert changeset = Payslip.update_amount_changeset(payslip, attrs)

      refute changeset.valid?
      assert errors_on(changeset) == %{amount: ["is invalid"]}
    end

    test "negative amount" do
      payslip = insert(:payslip, amount: 1_000_00)
      attrs = %{amount: -1}

      assert changeset = Payslip.update_amount_changeset(payslip, attrs)

      refute changeset.valid?
      assert errors_on(changeset) == %{amount: ["must be greater than 0,00"]}
    end
  end

  describe "assign_group/2" do
    test "assigns group_id to changeset" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, type: :regular, date: ~D[2021-02-01])

      attrs = %{
        org_id: org.id,
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28],
        registration_id: registration.id
      }

      assert changeset =
               attrs
               |> Payslip.create_changeset()
               |> Payslip.assign_group(group)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: attrs[:type],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date],
               registration_id: attrs[:registration_id],
               group_id: group.id
             }

      assert {:ok, _return} = Repo.insert(changeset)
    end

    test "when payslip and group belongs to different orgs" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, type: :regular, date: ~D[2021-02-01])

      attrs = %{
        org_id: org.id,
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28],
        registration_id: registration.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"group_id\" of relation \"payslips\" violates not-null constraint/,
                   fn ->
                     attrs
                     |> Payslip.create_changeset()
                     |> Payslip.assign_group(group)
                     |> Repo.insert()
                   end
    end

    test "when payslip and group have different types" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, type: :regular, date: ~D[2021-02-01])

      attrs = %{
        org_id: org.id,
        type: :vacation,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28],
        registration_id: registration.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"group_id\" of relation \"payslips\" violates not-null constraint/,
                   fn ->
                     attrs
                     |> Payslip.create_changeset()
                     |> Payslip.assign_group(group)
                     |> Repo.insert()
                   end
    end

    test "when payslip and group belongs to different month" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, type: :regular, date: ~D[2021-02-01])

      attrs = %{
        org_id: org.id,
        type: :regular,
        start_date: ~D[2021-01-01],
        end_date: ~D[2021-01-31],
        registration_id: registration.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"group_id\" of relation \"payslips\" violates not-null constraint/,
                   fn ->
                     attrs
                     |> Payslip.create_changeset()
                     |> Payslip.assign_group(group)
                     |> Repo.insert()
                   end
    end
  end
end
