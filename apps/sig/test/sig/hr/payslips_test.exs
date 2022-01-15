defmodule Sig.HR.PayslipsTest do
  use Sig.DataCase, async: true

  alias Sig.Entities.Companies.Company
  alias Sig.Entities.Entity
  alias Sig.Entities.Individuals.Individual
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Payslip{}} = Payslips.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Payslip{}} = Payslips.update_change(%Payslip{}, %{})
      assert %Ecto.Changeset{data: %Payslip{}} = Payslips.update_change(%Payslip{})
    end
  end

  describe "list_by/1 Registration" do
    test "lists payslips by registration ordered by decending start date" do
      registration = insert(:employee_registration)

      insert(:payslip,
        org: registration.org,
        registration: registration,
        start_date: ~D[2021-02-01]
      )

      insert(:payslip,
        org: registration.org,
        registration: registration,
        start_date: ~D[2021-01-01]
      )

      assert [
               %Payslip{start_date: ~D[2021-02-01]},
               %Payslip{start_date: ~D[2021-01-01]}
             ] = Payslips.list_by(registration)
    end

    test "apply limit" do
      registration = insert(:employee_registration)

      insert(:payslip,
        org: registration.org,
        registration: registration,
        start_date: ~D[2021-03-01]
      )

      insert(:payslip,
        org: registration.org,
        registration: registration,
        start_date: ~D[2021-02-01]
      )

      insert(:payslip,
        org: registration.org,
        registration: registration,
        start_date: ~D[2021-01-01]
      )

      assert [
               %Payslip{start_date: ~D[2021-03-01]},
               %Payslip{start_date: ~D[2021-02-01]}
             ] = Payslips.list_by(registration, limit: 2)
    end

    test "registration has no payslips" do
      registration = insert(:employee_registration)

      assert Payslips.list_by(registration) == []
    end
  end

  describe "list_by/1 Group" do
    test "lists payslips by group" do
      group = insert(:payslip_group)

      insert(:payslip,
        org: group.org,
        group: group,
        type: group.type,
        start_date: group.date
      )

      insert(:payslip,
        org: group.org,
        group: group,
        type: group.type,
        start_date: group.date
      )

      assert [%Payslip{}, %Payslip{}] = Payslips.list_by(group)
    end

    test "preloads" do
      group = insert(:payslip_group)

      insert(:payslip,
        org: group.org,
        group: group,
        type: group.type,
        start_date: group.date
      )

      assert [
               %Payslip{
                 registration: %Registration{
                   registered_at: %Company{},
                   individual: %Individual{}
                 }
               }
             ] = Payslips.list_by(group, preload_registration: true)
    end

    test "group has no payslips" do
      group = insert(:payslip_group)

      assert Payslips.list_by(group) == []
    end
  end

  describe "get/2 by Registration" do
    test "returns a payslip" do
      registration = insert(:employee_registration)

      %{id: id} = insert(:payslip, org: registration.org, registration: registration)

      assert %Payslip{id: ^id} = Payslips.get(registration, id)
    end

    test "payslip belongs to another registration" do
      registration = insert(:employee_registration)
      another_registration = insert(:employee_registration)

      %{id: id} =
        insert(:payslip, org: another_registration.org, registration: another_registration)

      assert Payslips.get(registration, id) == nil
    end

    test "payslip doesn't exist" do
      registration = insert(:employee_registration)

      assert Payslips.get(registration, UUID.generate()) == nil
    end
  end

  describe "get/2 by Group" do
    test "returns a payslip" do
      org = insert(:org)
      type = :regular
      start_date = ~D[2021-01-01]

      group = insert(:payslip_group, org: org, type: type, date: start_date)

      %{id: id} = insert(:payslip, org: org, group: group, type: type, start_date: start_date)

      assert %Payslip{id: ^id} = Payslips.get(group, id)
    end

    test "payslip belongs to another group" do
      org = insert(:org)
      type = :regular
      start_date = ~D[2021-01-01]

      group = insert(:payslip_group, org: org, type: type, date: start_date)

      %{id: id} = insert(:payslip, org: org, group: group, type: type, start_date: start_date)

      another_group = insert(:payslip_group, org: org, type: type, date: ~D[2021-02-01])

      assert Payslips.get(another_group, id) == nil
    end

    test "registration preloads" do
      org = insert(:org)
      type = :regular
      start_date = ~D[2021-01-01]

      group = insert(:payslip_group, org: org, type: type, date: start_date)

      %{id: id} = insert(:payslip, org: org, group: group, type: type, start_date: start_date)

      assert %Payslip{
               id: ^id,
               registration: %Registration{
                 registered_at: %Company{},
                 individual: %Individual{
                   entity: %Entity{}
                 }
               }
             } = Payslips.get(group, id, preload_registration: true)
    end

    test "payslip doesn't exist" do
      group = insert(:payslip_group)

      assert Payslips.get(group, UUID.generate()) == nil
    end
  end

  describe "get_by/2" do
    test "returns a payslip by attrs" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: id} = insert(:payslip, org: org, registration: registration)

      assert %Payslip{id: ^id} = Payslips.get_by(id: id, org_id: org.id)
    end

    test "registration preloads" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: id} = insert(:payslip, org: org, registration: registration)

      assert %Payslip{
               id: ^id,
               registration: %Registration{
                 registered_at: %Company{},
                 individual: %Individual{
                   entity: %Entity{}
                 }
               }
             } =
               %Payslip{id: ^id} =
               Payslips.get_by([id: id, org_id: org.id], preload_registration: true)
    end

    test "shallow preloads" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: id} = insert(:payslip, org: org, registration: registration)

      assert %Payslip{
               id: ^id,
               org: %Org{},
               registration: %Registration{}
             } =
               %Payslip{id: ^id} =
               Payslips.get_by([id: id, org_id: org.id], preload: [:registration, :org])
    end

    test "when field does't exist" do
      org = insert(:org)

      assert Payslips.get_by(id: UUID.generate(), org_id: org.id) == nil
    end
  end

  describe "toggle_is_closed/2" do
    test "toggles is_closed when false" do
      %{id: id} = payslip = insert(:payslip, is_closed: false)

      assert {:ok, %Payslip{id: ^id, is_closed: true}} = Payslips.toggle_is_closed(payslip)

      assert Repo.get_by(Payslip, org_id: payslip.org_id, id: id, is_closed: true)
    end

    test "toggles is_closed when true" do
      %{id: id} = payslip = insert(:payslip, is_closed: true)

      assert {:ok, %Payslip{id: ^id, is_closed: false}} = Payslips.toggle_is_closed(payslip)

      assert Repo.get_by(Payslip, org_id: payslip.org_id, id: id, is_closed: false)
    end
  end

  describe "update_payslip_amount/2" do
    test "updates the amount of the payslip based on the payslip items" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: Money.new(1_000_00)
        )

      payment_advance_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: true
        )

      health_insurance_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(300_00)
        )

      salary_supplement_item =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          description: "Complemento Salário",
          entry_type: :credit,
          amount: Money.new(200_00)
        )

      # Item from another payslip to be ignored
      to_ignore =
        insert(:payslip_outside_item,
          org: org,
          description: "Complemento Salário",
          entry_type: :credit,
          amount: Money.new(150_00)
        )

      items = [
        salary_item,
        payment_advance_item,
        health_insurance_item,
        salary_supplement_item,
        to_ignore
      ]

      assert {:ok, %Payslip{amount: %Money{amount: 500_00}}} =
               Payslips.update_payslip_amount(payslip, items)
    end

    test "when items brings the payslip amount to negative" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          description: "SALÁRIO",
          amount: Money.new(1_000_00)
        )

      payment_advance_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(1_100_00),
          is_payment_advance: true
        )

      items = [salary_item, payment_advance_item]

      assert Payslips.update_payslip_amount(payslip, items) ==
               {:error, "payslip amount can't be negative"}
    end

    test "when items brings the payslip amount to zero" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: Money.new(1_000_00)
        )

      payment_advance_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(1_000_00),
          is_payment_advance: true
        )

      items = [salary_item, payment_advance_item]

      assert {:ok, %Payslip{amount: %Money{amount: 0_00}}} =
               Payslips.update_payslip_amount(payslip, items)
    end
  end
end
