defmodule Sig.HR.Payslips.BatchCreatorTest do
  use Sig.DataCase

  alias Sig.Entities.Companies.Company
  alias Sig.Entities.Individuals.Individual
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips.BatchCreator
  alias Sig.HR.Payslips.Groups.Group
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Sector

  describe "changeset/3" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %BatchCreator.Attrs{}} = BatchCreator.changeset()
    end

    test "valid attrs" do
      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        sectors_ids: [UUID.generate(), UUID.generate()]
      }

      assert changeset = BatchCreator.changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: attrs[:type],
               start_date: attrs[:start_date],
               sectors_ids: attrs[:sectors_ids]
             }
    end

    test "invalid attrs" do
      attrs = %{
        type: :invalid,
        start_date: :invalid,
        sectors_ids: [:invalid, :invalid]
      }

      assert changeset = BatchCreator.changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               sectors_ids: ["is invalid"],
               start_date: ["is invalid"],
               type: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = BatchCreator.changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               type: ["can't be blank"],
               start_date: ["can't be blank"],
               sectors_ids: ["can't be blank"]
             }
    end
  end

  describe "verify/2" do
    test "returns the registrations from payslips to be created ordered by individual name" do
      org = insert(:org)

      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")
      cleaning_sector = insert(:org_sector, org: org, name: "cleaning")

      date = ~D[2021-01-01]
      type = :regular

      kitchen_individual = insert(:individual, org: org, name: "Zenon")
      cleaning_individual = insert(:individual, org: org, name: "Allan")

      registration_without_payables = [
        insert(:employee_registration,
          org: org,
          individual: kitchen_individual,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        ),
        insert(:employee_registration,
          org: org,
          individual: cleaning_individual,
          sector: cleaning_sector,
          admission_date: ~D[2020-01-01]
        )
      ]

      attrs = %{
        type: type,
        start_date: date,
        sectors_ids: [kitchen_sector.id, cleaning_sector.id]
      }

      assert {:ok,
              [
                %Registration{
                  individual: %Individual{name: "Allan"},
                  sector: %Sector{},
                  registered_at: %Company{}
                },
                %Registration{
                  individual: %Individual{name: "Zenon"},
                  sector: %Sector{},
                  registered_at: %Company{}
                }
              ] = return} = BatchCreator.verify(org, attrs)

      refute Repo.get_by(Group, org_id: org.id, date: date, type: type)

      returned_registrations_ids = Enum.map(return, & &1.id)

      Enum.each(registration_without_payables, fn new_registration ->
        refute Repo.get_by(Payslip, org_id: org.id, registration_id: new_registration.id)

        assert new_registration.id in returned_registrations_ids
      end)
    end

    test "returns the registrations from the payslips to be created when group and other payslips already exist" do
      org = insert(:org)

      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")
      cleaning_sector = insert(:org_sector, org: org, name: "cleaning")

      date = ~D[2021-01-01]
      type = :regular

      %{id: group_id} = group = insert(:payslip_group, org: org, date: date, type: type)

      existing_kitchen_sector_registration =
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        )

      existing_cleaning_sector_registration =
        insert(:employee_registration,
          org: org,
          sector: cleaning_sector,
          admission_date: ~D[2020-01-01]
        )

      # Existing payslips

      insert(:payslip,
        org: org,
        group: group,
        start_date: date,
        type: type,
        registration: existing_kitchen_sector_registration
      )

      insert(:payslip,
        org: org,
        group: group,
        start_date: date,
        type: type,
        registration: existing_cleaning_sector_registration
      )

      registrations_without_payables = [
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        ),
        insert(:employee_registration,
          org: org,
          sector: cleaning_sector,
          admission_date: ~D[2020-01-01]
        )
      ]

      attrs = %{
        type: type,
        start_date: date,
        sectors_ids: [kitchen_sector.id, cleaning_sector.id]
      }

      assert {:ok,
              [
                %Registration{
                  individual: %Individual{},
                  sector: %Sector{},
                  registered_at: %Company{}
                },
                %Registration{
                  individual: %Individual{},
                  sector: %Sector{},
                  registered_at: %Company{}
                }
              ] = return} = BatchCreator.verify(org, attrs)

      assert Repo.get_by(Group, org_id: org.id, id: group_id, date: date, type: type)

      returned_registrations_ids = Enum.map(return, & &1.id)

      Enum.each(registrations_without_payables, fn registration ->
        refute Repo.get_by(Payslip, org_id: org.id, registration_id: registration.id)

        assert registration.id in returned_registrations_ids
      end)
    end
  end

  describe "create/3" do
    test "batch creates payslips, payslip_items and payables" do
      org = insert(:org)

      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")
      cleaning_sector = insert(:org_sector, org: org, name: "cleaning")
      delivery_sector = insert(:org_sector, org: org, name: "delivery")

      kitchen_registrations =
        insert_list(2, :employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        )

      cleaning_registrations =
        insert_list(2, :employee_registration,
          org: org,
          sector: cleaning_sector,
          admission_date: ~D[2020-01-01]
        )

      insert_list(2, :employee_registration,
        org: org,
        sector: delivery_sector,
        admission_date: ~D[2020-01-01]
      )

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      Enum.each(kitchen_registrations ++ cleaning_registrations, fn registration ->
        insert({:employee_registration_recurring_payslip_item, :payslip_item},
          org: org,
          registration: registration,
          payslip_category: salary_category,
          item_amount: 300_00
        )

        insert({:employee_registration_recurring_payslip_item, :outside_item},
          org: org,
          registration: registration,
          item_amount: 100_00,
          outside_item_description: "OUTSIDE ITEM DEBIT",
          outside_item_entry_type: :debit,
          outside_item_is_payment_advance: true
        )
      end)

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        sectors_ids: [kitchen_sector.id, cleaning_sector.id]
      }

      payables_attrs = %{
        type: :standard,
        due_dates: %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-07]}
      }

      assert {:ok, [%Payslip{} | _] = payslips} =
               BatchCreator.create(org, attrs, payables_attrs: payables_attrs)

      assert Enum.count(payslips) == 4

      assert group = Repo.get_by(Group, org_id: org.id, date: ~D[2021-01-01], type: :regular)

      Enum.each(kitchen_registrations ++ cleaning_registrations, fn registration ->
        assert payslip =
                 Repo.get_by(Payslip,
                   org_id: org.id,
                   type: :regular,
                   start_date: ~D[2021-01-01],
                   end_date: ~D[2021-01-31],
                   amount: 200_00,
                   is_closed: false,
                   group_id: group.id,
                   registration_id: registration.id
                 )

        assert Repo.get_by(Item,
                 org_id: org.id,
                 amount: 300_00,
                 entry_type: :credit,
                 type: :payslip_item,
                 is_payment_advance: false,
                 payslip_id: payslip.id
               )

        assert Repo.get_by(Item,
                 org_id: org.id,
                 amount: 100_00,
                 entry_type: :debit,
                 type: :outside_item,
                 is_payment_advance: true,
                 payslip_id: payslip.id
               )

        # Salary advance

        assert salary_advance_payslip_payable =
                 Repo.get_by(PayslipPayable,
                   org_id: org.id,
                   payslip_id: payslip.id,
                   is_auto_adjustable_amount: false
                 )

        assert Repo.get_by(Payable,
                 id: salary_advance_payslip_payable.payable_id,
                 org_id: org.id,
                 target: :payslip,
                 due_date: ~D[2021-01-20],
                 reference_date: ~D[2021-01-01],
                 amount: 100_00,
                 financial_transaction_type: :cash,
                 description: "Adiantamento de Salário"
               )

        # Salary

        assert salary_payslip_payable =
                 Repo.get_by(PayslipPayable,
                   org_id: org.id,
                   payslip_id: payslip.id,
                   is_auto_adjustable_amount: true
                 )

        assert Repo.get_by(Payable,
                 id: salary_payslip_payable.payable_id,
                 org_id: org.id,
                 target: :payslip,
                 due_date: ~D[2021-02-07],
                 reference_date: ~D[2021-01-01],
                 amount: 200_00,
                 financial_transaction_type: :cash,
                 description: "Salário"
               )
      end)
    end

    test "batch creates payslips and payslips_items without payables" do
      org = insert(:org)

      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")
      cleaning_sector = insert(:org_sector, org: org, name: "cleaning")
      delivery_sector = insert(:org_sector, org: org, name: "delivery")

      registrations = [
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        ),
        insert(:employee_registration,
          org: org,
          sector: cleaning_sector,
          admission_date: ~D[2020-01-01]
        )
      ]

      insert(:employee_registration,
        org: org,
        sector: delivery_sector,
        admission_date: ~D[2020-01-01]
      )

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      Enum.each(registrations, fn registration ->
        insert({:employee_registration_recurring_payslip_item, :payslip_item},
          org: org,
          registration: registration,
          payslip_category: salary_category,
          item_amount: 300_00
        )

        insert({:employee_registration_recurring_payslip_item, :outside_item},
          org: org,
          registration: registration,
          item_amount: 100_00,
          outside_item_description: "OUTSIDE ITEM DEBIT",
          outside_item_entry_type: :debit,
          outside_item_is_payment_advance: true
        )
      end)

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        sectors_ids: [kitchen_sector.id, cleaning_sector.id]
      }

      assert {:ok, [%Payslip{}, %Payslip{}]} = BatchCreator.create(org, attrs)

      assert group = Repo.get_by(Group, org_id: org.id, date: ~D[2021-01-01], type: :regular)

      Enum.each(registrations, fn registration ->
        assert payslip =
                 Repo.get_by(Payslip,
                   org_id: org.id,
                   type: :regular,
                   start_date: ~D[2021-01-01],
                   end_date: ~D[2021-01-31],
                   amount: 200_00,
                   is_closed: false,
                   group_id: group.id,
                   registration_id: registration.id
                 )

        assert Repo.get_by(Item,
                 org_id: org.id,
                 amount: 300_00,
                 entry_type: :credit,
                 type: :payslip_item,
                 is_payment_advance: false,
                 payslip_id: payslip.id
               )

        assert Repo.get_by(Item,
                 org_id: org.id,
                 amount: 100_00,
                 entry_type: :debit,
                 type: :outside_item,
                 is_payment_advance: true,
                 payslip_id: payslip.id
               )

        refute Repo.get_by(PayslipPayable, org_id: org.id, payslip_id: payslip.id)

        refute Repo.get_by(Payable, org_id: org.id)
      end)
    end

    test "batch creates payslips when group and other payslips already exist" do
      %{id: org_id} = org = insert(:org)

      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")
      cleaning_sector = insert(:org_sector, org: org, name: "cleaning")
      delivery_sector = insert(:org_sector, org: org, name: "delivery")

      date = ~D[2021-01-01]
      type = :regular

      group = insert(:payslip_group, org: org, date: date, type: type)

      existing_kitchen_sector_registration =
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        )

      existing_cleaning_sector_registration =
        insert(:employee_registration,
          org: org,
          sector: cleaning_sector,
          admission_date: ~D[2020-01-01]
        )

      # Existing payslips

      insert(:payslip,
        org: org,
        group: group,
        start_date: date,
        type: type,
        registration: existing_kitchen_sector_registration
      )

      insert(:payslip,
        org: org,
        group: group,
        start_date: date,
        type: type,
        registration: existing_cleaning_sector_registration
      )

      registrations_without_payables = [
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        ),
        insert(:employee_registration,
          org: org,
          sector: cleaning_sector,
          admission_date: ~D[2020-01-01]
        )
      ]

      insert(:employee_registration,
        org: org,
        sector: delivery_sector,
        admission_date: ~D[2020-01-01]
      )

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      Enum.each(registrations_without_payables, fn registration ->
        insert({:employee_registration_recurring_payslip_item, :payslip_item},
          org: org,
          registration: registration,
          payslip_category: salary_category,
          item_amount: 300_00
        )

        insert({:employee_registration_recurring_payslip_item, :outside_item},
          org: org,
          registration: registration,
          item_amount: 100_00,
          outside_item_description: "OUTSIDE ITEM DEBIT",
          outside_item_entry_type: :debit,
          outside_item_is_payment_advance: true
        )
      end)

      attrs = %{
        type: type,
        start_date: date,
        sectors_ids: [kitchen_sector.id, cleaning_sector.id]
      }

      payables_attrs = %{
        type: :standard,
        due_dates: %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-07]}
      }

      assert {:ok, [%Payslip{}, %Payslip{}]} =
               BatchCreator.create(org, attrs, payables_attrs: payables_attrs)

      assert [%Group{org_id: ^org_id, date: ^date, type: ^type}] = Repo.all(Group)

      assert Repo.aggregate(Payslip, :count) == 4

      Enum.each(registrations_without_payables, fn registration ->
        assert payslip =
                 Repo.get_by(Payslip,
                   org_id: org.id,
                   type: :regular,
                   start_date: date,
                   end_date: Date.end_of_month(date),
                   amount: 200_00,
                   is_closed: false,
                   group_id: group.id,
                   registration_id: registration.id
                 )

        assert Repo.get_by(Item,
                 org_id: org.id,
                 amount: 300_00,
                 entry_type: :credit,
                 type: :payslip_item,
                 is_payment_advance: false,
                 payslip_id: payslip.id
               )

        assert Repo.get_by(Item,
                 org_id: org.id,
                 amount: 100_00,
                 entry_type: :debit,
                 type: :outside_item,
                 is_payment_advance: true,
                 payslip_id: payslip.id
               )

        # Salary advance

        assert salary_advance_payslip_payable =
                 Repo.get_by(PayslipPayable,
                   org_id: org.id,
                   payslip_id: payslip.id,
                   is_auto_adjustable_amount: false
                 )

        assert Repo.get_by(Payable,
                 id: salary_advance_payslip_payable.payable_id,
                 org_id: org.id,
                 target: :payslip,
                 due_date: ~D[2021-01-20],
                 reference_date: date,
                 amount: 100_00,
                 financial_transaction_type: :cash,
                 description: "Adiantamento de Salário"
               )

        # Salary

        assert salary_payslip_payable =
                 Repo.get_by(PayslipPayable,
                   org_id: org.id,
                   payslip_id: payslip.id,
                   is_auto_adjustable_amount: true
                 )

        assert Repo.get_by(Payable,
                 id: salary_payslip_payable.payable_id,
                 org_id: org.id,
                 target: :payslip,
                 due_date: ~D[2021-02-07],
                 reference_date: date,
                 amount: 200_00,
                 financial_transaction_type: :cash,
                 description: "Salário"
               )
      end)
    end

    test "admission date is after the beginning of the month and resignation date is before the end of the month" do
      org = insert(:org)
      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")

      registration =
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2021-01-10],
          resignation_date: ~D[2021-01-20],
          resignation_type: :dismissal
        )

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        item_amount: 100_00,
        outside_item_description: "OUTSIDE ITEM CREDIT",
        outside_item_entry_type: :credit
      )

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        sectors_ids: [kitchen_sector.id]
      }

      assert {:ok, [%Payslip{}]} = BatchCreator.create(org, attrs)

      assert group = Repo.get_by(Group, org_id: org.id, date: ~D[2021-01-01], type: :regular)

      assert payslip =
               Repo.get_by(Payslip,
                 org_id: org.id,
                 type: :regular,
                 start_date: ~D[2021-01-10],
                 end_date: ~D[2021-01-20],
                 amount: 100_00,
                 is_closed: false,
                 group_id: group.id,
                 registration_id: registration.id
               )

      assert Repo.get_by(Item,
               org_id: org.id,
               amount: 100_00,
               entry_type: :credit,
               type: :outside_item,
               is_payment_advance: false,
               payslip_id: payslip.id
             )
    end

    test "when payslip items brings the payslip amount to negative" do
      org = insert(:org)
      individual = insert(:individual, org: org, name: "Fulano")
      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")

      registration =
        insert(:employee_registration,
          org: org,
          individual: individual,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        )

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        item_amount: 100_00,
        outside_item_description: "OUTSIDE ITEM CREDIT",
        outside_item_entry_type: :credit
      )

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        item_amount: 200_00,
        outside_item_description: "OUTSIDE ITEM DEBIT",
        outside_item_entry_type: :debit
      )

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        sectors_ids: [kitchen_sector.id]
      }

      assert BatchCreator.create(org, attrs) ==
               {:error,
                "O total do holerite modelo de Fulano está negativo. Favor corrigir antes de gerar os holerites."}

      refute Repo.get_by(Group, org_id: org.id, date: ~D[2021-01-01], type: :regular)

      refute Repo.get_by(Payslip, org_id: org.id, registration_id: registration.id)
    end

    test "when there are duplicated recurring payslip items" do
      org = insert(:org)
      individual = insert(:individual, org: org, name: "Fulano")
      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")

      first_kitchen_registration =
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        )

      second_kitchen_registration =
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          individual: individual,
          admission_date: ~D[2020-01-01]
        )

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      Enum.each([first_kitchen_registration, second_kitchen_registration], fn registration ->
        insert({:employee_registration_recurring_payslip_item, :payslip_item},
          org: org,
          registration: registration,
          payslip_category: salary_category,
          item_amount: 300_00
        )
      end)

      # Duplicated recurring payslip item
      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: second_kitchen_registration,
        payslip_category: salary_category,
        item_amount: 100_00
      )

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        sectors_ids: [kitchen_sector.id]
      }

      payables_attrs = %{
        type: :standard,
        due_dates: %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-07]}
      }

      assert BatchCreator.create(org, attrs, payables_attrs: payables_attrs) ==
               {:error,
                "Existem itens duplicados no holerite modelo de Fulano. Favor corrigir antes de gerar os holerites."}

      refute Repo.get_by(Group, org_id: org.id)
      refute Repo.get_by(Payslip, org_id: org.id)
      refute Repo.get_by(Item, org_id: org.id)
      refute Repo.get_by(PayslipPayable, org_id: org.id)
      refute Repo.get_by(Payable, org_id: org.id)
    end

    test "invalid attrs" do
      org = insert(:org)

      assert {:error, changeset} = BatchCreator.create(org, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               type: ["can't be blank"],
               sectors_ids: ["can't be blank"],
               start_date: ["can't be blank"]
             }
    end

    test "invalid payables attrs" do
      org = insert(:org)

      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")
      cleaning_sector = insert(:org_sector, org: org, name: "cleaning")

      registrations = [
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        ),
        insert(:employee_registration,
          org: org,
          sector: cleaning_sector,
          admission_date: ~D[2020-01-01]
        )
      ]

      Enum.each(registrations, fn registration ->
        insert({:employee_registration_recurring_payslip_item, :outside_item},
          org: org,
          registration: registration,
          item_amount: 300_00,
          outside_item_description: "OUTSIDE ITEM CREDIT",
          outside_item_entry_type: :credit
        )

        insert({:employee_registration_recurring_payslip_item, :outside_item},
          org: org,
          registration: registration,
          item_amount: 100_00,
          outside_item_description: "OUTSIDE ITEM DEBIT",
          outside_item_entry_type: :debit,
          outside_item_is_payment_advance: true
        )
      end)

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        sectors_ids: [kitchen_sector.id, cleaning_sector.id]
      }

      assert {:ok, [%Payslip{}, %Payslip{}]} =
               BatchCreator.create(org, attrs, payables_attrs: :invalid)

      assert group = Repo.get_by(Group, org_id: org.id, date: ~D[2021-01-01], type: :regular)

      Enum.each(registrations, fn registration ->
        assert payslip =
                 Repo.get_by(Payslip,
                   org_id: org.id,
                   type: :regular,
                   start_date: ~D[2021-01-01],
                   end_date: ~D[2021-01-31],
                   amount: 200_00,
                   is_closed: false,
                   group_id: group.id,
                   registration_id: registration.id
                 )

        assert Repo.get_by(Item,
                 org_id: org.id,
                 amount: 300_00,
                 entry_type: :credit,
                 type: :outside_item,
                 is_payment_advance: false,
                 payslip_id: payslip.id
               )

        assert Repo.get_by(Item,
                 org_id: org.id,
                 amount: 100_00,
                 entry_type: :debit,
                 type: :outside_item,
                 is_payment_advance: true,
                 payslip_id: payslip.id
               )

        refute Repo.get_by(PayslipPayable, org_id: org.id, payslip_id: payslip.id)

        refute Repo.get_by(Payable, org_id: org.id)
      end)
    end

    test "org has no registrations" do
      org = insert(:org)

      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")
      cleaning_sector = insert(:org_sector, org: org, name: "cleaning")

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        sectors_ids: [kitchen_sector.id, cleaning_sector.id]
      }

      assert BatchCreator.create(org, attrs) ==
               {:error, "Não existem registros de funcionários para os setores nesta data"}
    end

    test "registrations has no recurring payslip items" do
      org = insert(:org)

      kitchen_sector = insert(:org_sector, org: org, name: "kitchen")
      cleaning_sector = insert(:org_sector, org: org, name: "cleaning")

      registrations = [
        insert(:employee_registration,
          org: org,
          sector: kitchen_sector,
          admission_date: ~D[2020-01-01]
        ),
        insert(:employee_registration,
          org: org,
          sector: cleaning_sector,
          admission_date: ~D[2020-01-01]
        )
      ]

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        sectors_ids: [kitchen_sector.id, cleaning_sector.id]
      }

      payables_attrs = %{
        type: :standard,
        due_dates: %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-07]}
      }

      assert {:ok, [%Payslip{} | _] = payslips} =
               BatchCreator.create(org, attrs, payables_attrs: payables_attrs)

      assert Enum.count(payslips) == 2

      assert group = Repo.get_by(Group, org_id: org.id, date: ~D[2021-01-01], type: :regular)

      Enum.each(registrations, fn registration ->
        assert payslip =
                 Repo.get_by(Payslip,
                   org_id: org.id,
                   type: :regular,
                   start_date: ~D[2021-01-01],
                   end_date: ~D[2021-01-31],
                   amount: 0,
                   is_closed: false,
                   group_id: group.id,
                   registration_id: registration.id
                 )

        refute Repo.get_by(Item, org_id: org.id, payslip_id: payslip.id)

        # Salary advance

        refute Repo.get_by(PayslipPayable,
                 org_id: org.id,
                 payslip_id: payslip.id,
                 is_auto_adjustable_amount: false
               )

        refute Repo.get_by(Payable, org_id: org.id, description: "Adiantamento de Salário")

        # Salary

        assert salary_payslip_payable =
                 Repo.get_by(PayslipPayable,
                   org_id: org.id,
                   payslip_id: payslip.id,
                   is_auto_adjustable_amount: true
                 )

        assert Repo.get_by(Payable,
                 id: salary_payslip_payable.payable_id,
                 org_id: org.id,
                 target: :payslip,
                 due_date: ~D[2021-02-07],
                 reference_date: ~D[2021-01-01],
                 amount: 0,
                 financial_transaction_type: :cash,
                 description: "Salário"
               )
      end)
    end
  end
end
