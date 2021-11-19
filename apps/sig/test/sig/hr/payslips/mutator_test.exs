defmodule Sig.HR.Payslips.MutatorTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Mutator
  alias Sig.HR.Payslips.Groups.Group
  alias Sig.HR.Payslips.Payslip

  describe "create/1" do
    test "creates a payslip when group already exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      group = insert(:payslip_group, org: org, type: :regular, date: ~D[2021-02-01])

      attrs = %{
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28]
      }

      assert {:ok, %Payslip{id: id}} = Mutator.create(registration, attrs)

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

      assert {:ok, %Payslip{id: id, group_id: group_id}} = Mutator.create(registration, attrs)

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

      assert Mutator.create(registration, attrs) ==
               {:error, "payslip start date can't be before registration admission date"}

      refute Repo.get_by(Payslip, org_id: org.id, registration_id: registration.id)
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Mutator.create(registration, %{})

      assert errors_on(changeset) == %{
               end_date: ["can't be blank"],
               start_date: ["can't be blank"],
               type: ["can't be blank"]
             }
    end
  end

  describe "update/2" do
    test "updates a payslip" do
      start_date = ~D[2021-01-01]
      end_date = ~D[2021-01-31]
      type = :regular

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      group = insert(:payslip_group, org: org, type: :regular, date: start_date, type: type)

      %{id: payslip_id} =
        payslip =
        insert(:payslip,
          org: org,
          group: group,
          registration: registration,
          type: type,
          start_date: start_date,
          end_date: end_date
        )

      attrs = %{
        start_date: ~D[2021-03-01],
        end_date: ~D[2021-03-31],
        type: :vacation
      }

      assert {:ok, %Payslip{id: ^payslip_id}} = Mutator.update(payslip, attrs)

      assert updated_payslip =
               Repo.get_by(Payslip,
                 org_id: org.id,
                 id: payslip.id,
                 registration_id: registration.id,
                 start_date: attrs[:start_date],
                 end_date: attrs[:end_date],
                 type: attrs[:type]
               )

      refute updated_payslip.group_id == group.id

      assert new_group =
               Repo.get_by(Group,
                 org_id: org.id,
                 type: attrs[:type],
                 date: Date.beginning_of_month(attrs[:start_date])
               )

      assert updated_payslip.group_id == new_group.id
    end

    test "when payslip is closed before is loaded" do
      start_date = ~D[2021-01-01]
      end_date = ~D[2021-01-31]
      type = :regular

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      group = insert(:payslip_group, org: org, type: :regular, date: start_date, type: type)

      payslip =
        insert(:payslip,
          org: org,
          group: group,
          registration: registration,
          type: type,
          start_date: start_date,
          end_date: end_date,
          is_closed: true
        )

      attrs = %{
        start_date: ~D[2021-03-01],
        end_date: ~D[2021-03-31],
        type: :vacation
      }

      assert Mutator.update(payslip, attrs) == {:error, "can't modify a closed payslip"}

      refute Repo.get_by(Payslip,
               org_id: org.id,
               id: payslip.id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               end_date: attrs[:end_date],
               type: attrs[:type]
             )

      refute Repo.get_by(Group,
               org_id: org.id,
               type: attrs[:type],
               date: Date.beginning_of_month(attrs[:start_date])
             )
    end

    test "when payslip is closed after is loaded" do
      start_date = ~D[2021-01-01]
      end_date = ~D[2021-01-31]
      type = :regular

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      group = insert(:payslip_group, org: org, type: :regular, date: start_date, type: type)

      payslip =
        insert(:payslip,
          org: org,
          group: group,
          registration: registration,
          type: type,
          start_date: start_date,
          end_date: end_date
        )

      # Close payslip
      Repo.update(change(payslip, is_closed: true))

      attrs = %{
        start_date: ~D[2021-03-01],
        end_date: ~D[2021-03-31],
        type: :vacation
      }

      assert Mutator.update(payslip, attrs) == {:error, "can't modify a closed payslip"}

      refute Repo.get_by(Payslip,
               org_id: org.id,
               id: payslip.id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               end_date: attrs[:end_date],
               type: attrs[:type]
             )

      refute Repo.get_by(Group,
               org_id: org.id,
               type: attrs[:type],
               date: Date.beginning_of_month(attrs[:start_date])
             )
    end

    test "when start date is before registration admission date" do
      start_date = ~D[2021-01-01]
      end_date = ~D[2021-01-31]
      type = :regular

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      group = insert(:payslip_group, org: org, type: :regular, date: start_date, type: type)

      payslip =
        insert(:payslip,
          org: org,
          group: group,
          registration: registration,
          type: type,
          start_date: start_date,
          end_date: end_date
        )

      attrs = %{
        start_date: ~D[2020-12-01],
        end_date: ~D[2020-12-31],
        type: :vacation
      }

      assert Mutator.update(payslip, attrs) ==
               {:error, "payslip start date can't be before registration admission date"}

      refute Repo.get_by(Payslip,
               org_id: org.id,
               id: payslip.id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               end_date: attrs[:end_date],
               type: attrs[:type]
             )

      refute Repo.get_by(Group,
               org_id: org.id,
               type: attrs[:type],
               date: Date.beginning_of_month(attrs[:start_date])
             )
    end

    test "empty attrs" do
      start_date = ~D[2021-01-01]
      end_date = ~D[2021-01-31]
      type = :regular

      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      group = insert(:payslip_group, org: org, type: :regular, date: start_date, type: type)

      %{id: payslip_id} =
        payslip =
        insert(:payslip,
          org: org,
          group: group,
          registration: registration,
          type: type,
          start_date: start_date,
          end_date: end_date
        )

      assert {:ok, %Payslip{id: ^payslip_id}} = Mutator.update(payslip, %{})
    end
  end
end
