defmodule Sig.HR.Payslips.Items.MutatorTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Payslips.Items.Mutator

  describe "create_payslip_item/2" do
    test "creates a payslip item and updates payslip amount when no item exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      attrs = %{
        amount: 2_000_00,
        category_id: category.id
      }

      assert {:ok, %Item{id: id}} = Mutator.create_payslip_item(payslip, attrs)

      assert Repo.get_by(Item,
               id: id,
               org_id: org.id,
               payslip_id: payslip.id,
               category_id: category.id,
               description: category.description,
               entry_type: category.entry_type,
               code: category.code,
               type: :payslip_item,
               amount: attrs[:amount],
               is_payment_advance: category.is_payment_advance
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: attrs[:amount]
             )
    end

    test "creates a positive payslip item and updates payslip amount when items already exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      cashier_category =
        insert(:payslip_category,
          org: org,
          code: "1000",
          entry_type: :credit,
          description: "QUEBRA DE CAIXA"
        )

      insert(:payslip_item, org: org, payslip: payslip, category: cashier_category, amount: 200_00)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 300_00))

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      attrs = %{
        amount: 1_000_00,
        category_id: salary_category.id
      }

      assert {:ok, %Item{id: id}} = Mutator.create_payslip_item(payslip, attrs)

      assert Repo.get_by(Item,
               id: id,
               org_id: org.id,
               payslip_id: payslip.id,
               category_id: salary_category.id,
               description: salary_category.description,
               entry_type: salary_category.entry_type,
               code: salary_category.code,
               type: :payslip_item,
               amount: attrs[:amount],
               is_payment_advance: salary_category.is_payment_advance
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 1_300_00
             )
    end

    test "creates a negative payslip item and updates payslip amount when items already exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 900_00))

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      attrs = %{
        amount: 300_00,
        category_id: health_insurance_category.id
      }

      assert {:ok, %Item{id: id}} = Mutator.create_payslip_item(payslip, attrs)

      assert Repo.get_by(Item,
               id: id,
               org_id: org.id,
               payslip_id: payslip.id,
               category_id: health_insurance_category.id,
               description: health_insurance_category.description,
               entry_type: health_insurance_category.entry_type,
               code: health_insurance_category.code,
               type: :payslip_item,
               amount: attrs[:amount],
               is_payment_advance: health_insurance_category.is_payment_advance
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 600_00
             )
    end

    test "when new payslip item brings payslip amount to negative" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 900_00))

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      attrs = %{
        amount: 2_000_00,
        category_id: health_insurance_category.id
      }

      assert {:error, "payslip amount can't be negative"} =
               Mutator.create_payslip_item(payslip, attrs)

      refute Repo.get_by(Item,
               org_id: org.id,
               payslip_id: payslip.id,
               category_id: health_insurance_category.id,
               type: :payslip_item,
               amount: attrs[:amount]
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 900_00
             )
    end

    test "when new payslip item brings payslip amount to zero" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 900_00))

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      attrs = %{
        amount: 900_00,
        category_id: health_insurance_category.id
      }

      assert {:ok, %Item{id: id}} = Mutator.create_payslip_item(payslip, attrs)

      assert Repo.get_by(Item,
               id: id,
               org_id: org.id,
               payslip_id: payslip.id,
               category_id: health_insurance_category.id,
               description: health_insurance_category.description,
               entry_type: health_insurance_category.entry_type,
               code: health_insurance_category.code,
               type: :payslip_item,
               amount: attrs[:amount],
               is_payment_advance: health_insurance_category.is_payment_advance
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 0
             )
    end

    test "when payslip is initially closed" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, is_closed: false)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      # Close payslip
      payslip = Repo.update!(change(payslip, amount: 900_00, is_closed: true))

      attrs = %{
        amount: 300_00,
        category_id: health_insurance_category.id
      }

      assert {:error, "can't modify a closed payslip"} =
               Mutator.create_payslip_item(payslip, attrs)

      refute Repo.get_by(Item,
               org_id: org.id,
               payslip_id: payslip.id,
               category_id: health_insurance_category.id,
               description: health_insurance_category.description,
               entry_type: health_insurance_category.entry_type,
               code: health_insurance_category.code,
               type: :payslip_item,
               amount: attrs[:amount],
               is_payment_advance: health_insurance_category.is_payment_advance
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 900_00
             )
    end

    test "when payslip is closed after is loaded" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, is_closed: false)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      # Close payslip
      Repo.update!(change(payslip, amount: 900_00, is_closed: true))

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      attrs = %{
        amount: 300_00,
        category_id: health_insurance_category.id
      }

      assert {:error, "can't modify a closed payslip"} =
               Mutator.create_payslip_item(payslip, attrs)

      refute Repo.get_by(Item,
               org_id: org.id,
               payslip_id: payslip.id,
               category_id: health_insurance_category.id,
               type: :payslip_item,
               amount: attrs[:amount]
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 900_00
             )
    end

    test "returns changeset errors" do
      payslip = insert(:payslip)

      assert {:error, changeset} = Mutator.create_payslip_item(payslip, %{})

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               category_id: ["can't be blank"],
               code: ["can't be blank"],
               description: ["can't be blank"],
               entry_type: ["can't be blank"]
             }
    end
  end

  describe "create_outside_item/2" do
    test "creates a payslip outside item and updates payslip amount when no item exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: Money.new(0))

      attrs = %{
        amount: 2_000_00,
        description: Faker.Lorem.sentence(),
        entry_type: :credit
      }

      assert {:ok, %Item{id: id}} = Mutator.create_outside_item(payslip, attrs)

      assert Repo.get_by(Item,
               id: id,
               org_id: org.id,
               payslip_id: payslip.id,
               type: :outside_item,
               amount: attrs[:amount],
               description: attrs[:description],
               entry_type: attrs[:entry_type]
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: attrs[:amount]
             )
    end

    test "creates a positive outside item and updates payslip amount when items already exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: Money.new(300_00))

      cashier_category =
        insert(:payslip_category,
          org: org,
          code: "1000",
          entry_type: :credit,
          description: "QUEBRA DE CAIXA"
        )

      insert(:payslip_item, org: org, payslip: payslip, category: cashier_category, amount: 200_00)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      attrs = %{
        amount: 1_000_00,
        description: Faker.Lorem.sentence(),
        entry_type: :credit
      }

      assert {:ok, %Item{id: id}} = Mutator.create_outside_item(payslip, attrs)

      assert Repo.get_by(Item,
               id: id,
               org_id: org.id,
               payslip_id: payslip.id,
               type: :outside_item,
               amount: attrs[:amount],
               description: attrs[:description],
               entry_type: attrs[:entry_type]
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 1_300_00
             )
    end

    test "creates a negative outside item and updates payslip amount when items already exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: Money.new(900_00))

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      attrs = %{
        amount: 300_00,
        description: Faker.Lorem.sentence(),
        entry_type: :debit
      }

      assert {:ok, %Item{id: id}} = Mutator.create_outside_item(payslip, attrs)

      assert Repo.get_by(Item,
               id: id,
               org_id: org.id,
               payslip_id: payslip.id,
               type: :outside_item,
               amount: attrs[:amount],
               description: attrs[:description],
               entry_type: attrs[:entry_type]
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 600_00
             )
    end

    test "when new outside item brings payslip amount to negative" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 900_00))

      attrs = %{
        amount: 2_000_00,
        description: Faker.Lorem.sentence(),
        entry_type: :debit
      }

      assert {:error, "payslip amount can't be negative"} =
               Mutator.create_outside_item(payslip, attrs)

      refute Repo.get_by(Item,
               org_id: org.id,
               payslip_id: payslip.id,
               type: :outside_item,
               amount: attrs[:amount],
               description: attrs[:description],
               entry_type: attrs[:entry_type]
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 900_00
             )
    end

    test "when new outside item brings payslip amount to zero" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 900_00))

      attrs = %{
        amount: 900_00,
        description: Faker.Lorem.sentence(),
        entry_type: :debit
      }

      assert {:ok, %Item{id: id}} = Mutator.create_outside_item(payslip, attrs)

      assert Repo.get_by(Item,
               id: id,
               org_id: org.id,
               payslip_id: payslip.id,
               type: :outside_item,
               amount: attrs[:amount],
               description: attrs[:description],
               entry_type: attrs[:entry_type]
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 0
             )
    end

    test "when payslip is initially closed" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, is_closed: false)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      # Close payslip
      payslip = Repo.update!(change(payslip, amount: 900_00, is_closed: true))

      attrs = %{
        amount: 300_00,
        description: Faker.Lorem.sentence(),
        entry_type: :debit
      }

      assert {:error, "can't modify a closed payslip"} =
               Mutator.create_outside_item(payslip, attrs)

      refute Repo.get_by(Item,
               org_id: org.id,
               payslip_id: payslip.id,
               type: :outside_item,
               amount: attrs[:amount],
               description: attrs[:description],
               entry_type: attrs[:entry_type]
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 900_00
             )
    end

    test "when payslip is closed after is loaded" do
      org = insert(:org)

      payslip = insert(:payslip, org: org, is_closed: false)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_category,
        amount: 1_000_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      # Close payslip
      Repo.update!(change(payslip, amount: 900_00, is_closed: true))

      attrs = %{
        amount: 300_00,
        description: Faker.Lorem.sentence(),
        entry_type: :debit
      }

      assert {:error, "can't modify a closed payslip"} =
               Mutator.create_outside_item(payslip, attrs)

      refute Repo.get_by(Item,
               org_id: org.id,
               payslip_id: payslip.id,
               type: :outside_item,
               amount: attrs[:amount],
               description: attrs[:description],
               entry_type: attrs[:entry_type]
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 900_00
             )
    end

    test "returns changeset errors" do
      payslip = insert(:payslip)

      assert {:error, changeset} = Mutator.create_outside_item(payslip, %{})

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               description: ["can't be blank"],
               entry_type: ["can't be blank"]
             }
    end
  end

  describe "update_amount/3" do
    test "updates the amount of a payslip item" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: Money.new(300_00))

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      cashier_category =
        insert(:payslip_category,
          org: org,
          code: "1000",
          entry_type: :credit,
          description: "QUEBRA DE CAIXA"
        )

      payslip_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: cashier_category,
          amount: 200_00
        )

      attrs = %{amount: 250_00}

      assert {:ok, %Item{amount: %Money{amount: 250_00}}} =
               Mutator.update_amount(payslip, payslip_item, attrs)

      assert Repo.get_by(Item,
               id: payslip_item.id,
               org_id: org.id,
               payslip_id: payslip.id,
               category_id: cashier_category.id,
               type: :payslip_item,
               reference: payslip_item.reference,
               amount: 250_00
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 350_00
             )
    end

    test "updates the amount of an outside item" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: Money.new(300_00))

      cashier_category =
        insert(:payslip_category,
          org: org,
          code: "1000",
          entry_type: :credit,
          description: "QUEBRA DE CAIXA"
        )

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: cashier_category,
        amount: 200_00
      )

      outside_item =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: 100_00
        )

      attrs = %{amount: 200_00}

      assert {:ok, %Item{amount: %Money{amount: 200_00}}} =
               Mutator.update_amount(payslip, outside_item, attrs)

      assert Repo.get_by(Item,
               id: outside_item.id,
               org_id: org.id,
               payslip_id: payslip.id,
               type: :outside_item,
               description: outside_item.description,
               entry_type: outside_item.entry_type,
               amount: 200_00
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 400_00
             )
    end

    test "when the item update brings payslip amount to negative" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      cashier_category =
        insert(:payslip_category,
          org: org,
          code: "1000",
          entry_type: :credit,
          description: "QUEBRA DE CAIXA"
        )

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: cashier_category,
        amount: 200_00
      )

      outside_item =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: 100_00
        )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      attrs = %{amount: 250_00}

      assert {:error, "payslip amount can't be negative"} =
               Mutator.update_amount(payslip, outside_item, attrs)

      refute Repo.get_by(Item,
               id: outside_item.id,
               org_id: org.id,
               payslip_id: payslip.id,
               amount: 250_00
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 100_00
             )
    end

    test "when the item update brings payslip amount to zero" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: Money.new(100_00))

      cashier_category =
        insert(:payslip_category,
          org: org,
          code: "1000",
          entry_type: :credit,
          description: "QUEBRA DE CAIXA"
        )

      payslip_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: cashier_category,
          amount: 200_00
        )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      attrs = %{amount: 100_00}

      assert {:ok, %Item{}} = Mutator.update_amount(payslip, payslip_item, attrs)

      assert Repo.get_by(Item,
               id: payslip_item.id,
               org_id: org.id,
               payslip_id: payslip.id,
               amount: 100_00
             )

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 0
             )
    end

    test "when item belong to another payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      another_payslip = insert(:payslip, org: org)

      item =
        insert(:payslip_outside_item,
          org: org,
          payslip: another_payslip,
          entry_type: :credit,
          amount: 100_00
        )

      # Update payslip amount
      Repo.update!(change(another_payslip, amount: 100_00))

      attrs = %{amount: 200_00}

      assert {:error, "item doesn't belong to payslip"} =
               Mutator.update_amount(payslip, item, attrs)

      assert Repo.get_by(Item, id: item.id, org_id: org.id, amount: 100_00)

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 0
             )

      assert Repo.get_by(Payslip,
               id: another_payslip.id,
               org_id: org.id,
               amount: 100_00
             )
    end

    test "when payslip is initially closed" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: salary_category,
          amount: 1_000_00
        )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 100_00
      )

      # Update payslip
      payslip = Repo.update!(change(payslip, amount: 900_00, is_closed: true))

      attrs = %{amount: 1_200_00}

      assert {:error, "can't modify a closed payslip"} =
               Mutator.update_amount(payslip, item, attrs)

      assert Repo.get_by(Item, org_id: org.id, id: item.id, amount: 1_000_00)
      assert Repo.get_by(Payslip, org_id: org.id, id: payslip.id, amount: 900_00)
    end

    test "when payslip is closed after is loaded" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, is_closed: false)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      item =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: 100_00
        )

      # Close payslip
      Repo.update!(change(payslip, amount: 100_00, is_closed: true))

      attrs = %{amount: 120_00}

      assert {:error, "can't modify a closed payslip"} =
               Mutator.update_amount(payslip, item, attrs)

      assert Repo.get_by(Item, org_id: org.id, id: item.id, amount: 100_00)
      assert Repo.get_by(Payslip, org_id: org.id, id: payslip.id, amount: 100_00)
    end

    test "when amount is negative" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 300_00
      )

      item =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: 100_00
        )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      attrs = %{amount: -1}

      assert {:error, changeset} = Mutator.update_amount(payslip, item, attrs)

      assert errors_on(changeset) == %{
               amount: ["must be greater than or equal to 0,00"]
             }

      assert Repo.get_by(Item, org_id: org.id, id: item.id, amount: 100_00)
      assert Repo.get_by(Payslip, org_id: org.id, id: payslip.id, amount: 200_00)
    end
  end

  describe "delete_item/2" do
    test "deletes the only item" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: Money.new(300_00))

      %{id: id} =
        item =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: 300_00
        )

      assert {:ok, %Item{id: ^id}} = Mutator.delete_item(payslip, item)

      refute Repo.get_by(Item, org_id: org.id, id: id)

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 0
             )
    end

    test "deletes an item when other items exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: Money.new(300_00))

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      cashier_category =
        insert(:payslip_category,
          org: org,
          code: "1000",
          entry_type: :credit,
          description: "QUEBRA DE CAIXA"
        )

      %{id: id} =
        item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: cashier_category,
          amount: 200_00
        )

      assert {:ok, %Item{id: ^id}} = Mutator.delete_item(payslip, item)

      refute Repo.get_by(Item, org_id: org.id, id: id)

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 100_00
             )
    end

    test "when item belongs to another payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      another_payslip = insert(:payslip, org: org)

      item =
        insert(:payslip_outside_item,
          org: org,
          payslip: another_payslip,
          entry_type: :credit,
          amount: 100_00
        )

      # Update payslip amount
      Repo.update!(change(another_payslip, amount: 100_00))

      assert {:error, "item doesn't belong to payslip"} = Mutator.delete_item(payslip, item)

      assert Repo.get_by(Item, id: item.id, org_id: org.id)

      assert Repo.get_by(Payslip,
               id: payslip.id,
               org_id: org.id,
               amount: 0
             )

      assert Repo.get_by(Payslip,
               id: another_payslip.id,
               org_id: org.id,
               amount: 100_00
             )
    end
  end
end
