defmodule Sig.HR.Payslips.CreateTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Create
  alias Sig.HR.Payslips.Groups.Group
  alias Sig.HR.Payslips.Payslip

  describe "call/1" do
    test "creates a payslip when group already exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, type: :regular, date: ~D[2021-02-01])

      attrs = %{
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28]
      }

      assert {:ok, %Payslip{id: id}} = Create.call(registration, attrs)

      assert Repo.get_by(Payslip,
               amount: 0,
               id: id,
               org_id: org.id,
               registration_id: registration.id,
               group_id: group.id,
               type: group.type,
               start_date: attrs[:start_date],
               end_date: attrs[:end_date]
             )
    end

    test "creates a payslip and a group when group doesn't exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28]
      }

      assert {:ok, %Payslip{id: id, group_id: group_id}} = Create.call(registration, attrs)

      assert Repo.get_by(Payslip,
               amount: 0,
               id: id,
               org_id: org.id,
               registration_id: registration.id,
               type: attrs[:type],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date]
             )

      assert Repo.get_by(Group,
               id: group_id,
               org_id: org.id,
               date: attrs[:start_date] |> Date.beginning_of_month(),
               type: attrs[:type]
             )
    end

    test "when start date is before registration admission date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-03-01])

      attrs = %{
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28]
      }

      assert Create.call(registration, attrs) ==
               {:error, "payslip start date can't be before registration admission date"}

      refute Repo.get_by(Payslip, org_id: org.id, registration_id: registration.id)
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Create.call(registration, %{})

      assert errors_on(changeset) == %{
               end_date: ["can't be blank"],
               start_date: ["can't be blank"],
               type: ["can't be blank"]
             }
    end
  end
end
