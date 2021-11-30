defmodule Sig.HR.Payslips.Groups.GroupTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Groups.Group

  describe "payslip_groups table constraints" do
    test "org_id not_null_violation" do
      group = %Group{
        type: random_enum_value(:payslip_group_type),
        date: Date.utc_today() |> Date.beginning_of_month()
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"payslip_groups\" violates not-null constraint/,
                   fn -> Repo.insert(group) end
    end

    test "org_id foreign_key_constraint" do
      group = %Group{
        org_id: UUID.generate(),
        type: random_enum_value(:payslip_group_type),
        date: Date.utc_today() |> Date.beginning_of_month()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_groups_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(group) end
    end

    test "payslip_groups_date_unique unique constraint" do
      org = insert(:org)
      insert(:payslip_group, org: org, type: :regular, date: ~D[2020-01-01])

      group = %Group{
        org_id: org.id,
        type: :regular,
        date: ~D[2020-01-01]
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_groups_date_unique \(unique_constraint\)/,
                   fn -> Repo.insert(group) end
    end

    test "payslip_groups_date_beginning_of_month constraint" do
      org = insert(:org)

      group = %Group{
        org_id: org.id,
        date: ~D[2020-01-02],
        type: random_enum_value(:payslip_group_type)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_groups_date_beginning_of_month \(check_constraint\)/,
                   fn -> Repo.insert(group) end
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        date: ~D[2021-01-01],
        type: random_enum_value(:payslip_group_type)
      }

      assert changeset = Group.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               date: attrs[:date],
               type: attrs[:type]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        date: :invalid,
        type: :invalid
      }

      assert changeset = Group.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               date: ["is invalid"],
               org_id: ["is invalid"],
               type: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = Group.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               date: ["can't be blank"],
               org_id: ["can't be blank"],
               type: ["can't be blank"]
             }
    end

    test "ensure date is beginning of month" do
      attrs = %{
        org_id: UUID.generate(),
        date: ~D[2021-01-15],
        type: random_enum_value(:payslip_group_type)
      }

      assert changeset = Group.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               date: ~D[2021-01-01],
               type: attrs[:type]
             }
    end
  end
end
