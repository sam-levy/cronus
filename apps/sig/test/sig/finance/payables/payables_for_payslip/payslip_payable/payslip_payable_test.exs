defmodule Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayableTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "payslip_payables table constraints" do
    test "org_id not_null_violation" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      payable = insert(:payable_cash, org: org)

      payslip_payable = %PayslipPayable{
        payslip_id: payslip.id,
        payable_id: payable.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"payslip_payables\" violates not-null constraint/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "org_id foreign_key_constraint" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      payable = insert(:payable_cash, org: org)

      payslip_payable = %PayslipPayable{
        org_id: UUID.generate(),
        payslip_id: payslip.id,
        payable_id: payable.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "payslip_id not_null_violation" do
      org = insert(:org)
      payable = insert(:payable_cash, org: org)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payable_id: payable.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"payslip_id\" of relation \"payslip_payables\" violates not-null constraint/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "payslip_id foreign_key_constraint" do
      org = insert(:org)
      payable = insert(:payable_cash, org: org)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payslip_id: UUID.generate(),
        payable_id: payable.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_payslip_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "payable_id not_null_violation" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payslip_id: payslip.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"payable_id\" of relation \"payslip_payables\" violates not-null constraint/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "payable_id foreign_key_constraint" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payslip_id: payslip.id,
        payable_id: UUID.generate()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_payable_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "payslip_payables_payable_unique" do
      org = insert(:org)

      payslip_1 = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip_1,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip_1 amount
      Repo.update!(change(payslip_1, amount: 100_00))

      payslip_2 = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip_2,
        entry_type: :credit,
        amount: 200_00
      )

      # Update payslip_2 amount
      Repo.update!(change(payslip_2, amount: 200_00))

      payable = insert(:payable_cash, org: org, amount: 100_00)

      insert(:payslip_payable, org: org, payslip: payslip_1, payable: payable)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payslip_id: payslip_2.id,
        payable_id: payable.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_payables_payable_unique \(unique_constraint\)/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "payslip_payables_is_auto_adjustable_amount_true_unique unique" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      existing_payable = insert(:payable_cash, org: org, amount: 50_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: existing_payable,
        is_auto_adjustable_amount: true
      )

      payable = insert(:payable_cash, org: org, amount: 50_00)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payslip_id: payslip.id,
        payable_id: payable.id,
        is_auto_adjustable_amount: true
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_payables_is_auto_adjustable_amount_true_unique \(unique_constraint\)/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "success" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      payable = insert(:payable_cash, org: org, amount: 100_00)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payslip_id: payslip.id,
        payable_id: payable.id,
        is_auto_adjustable_amount: true
      }

      assert %PayslipPayable{} = Repo.insert!(payslip_payable)
    end
  end

  describe "validate_payables_amount_sum_for_payslip_procedure" do
    test "payables sum can't exceed the payslip amount plus payments in advance items amount sum" do
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

      salary_advance_category =
        insert(:payslip_category,
          org: org,
          code: "12",
          entry_type: :debit,
          description: "ADIANTAMENTO ANTERIOR"
        )

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_advance_category,
        amount: 400_00,
        is_payment_advance: true
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 600_00))

      salary_advance_payable =
        insert(:payable_bank_transfer, target: :payslip, org: org, amount: 400_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: salary_advance_payable,
        is_auto_adjustable_amount: false
      )

      salary_payable = insert(:payable_bank_transfer, target: :payslip, org: org, amount: 601_00)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payslip_id: payslip.id,
        payable_id: salary_payable.id,
        is_auto_adjustable_amount: false
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) payables amount sum cannot exceed the payslip amount plus payments in advance items/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "when debit payslip_item is not a payment in advance" do
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

      transport_voucher_category =
        insert(:payslip_category,
          org: org,
          code: "109",
          entry_type: :debit,
          description: "DESC. VALE TRANSPORTE"
        )

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: transport_voucher_category,
        amount: 10_00,
        is_payment_advance: false
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 990_00))

      salary_payable =
        insert(:payable_bank_transfer, target: :payslip, org: org, amount: 1_000_00)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payslip_id: payslip.id,
        payable_id: salary_payable.id,
        is_auto_adjustable_amount: false
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) payables amount sum cannot exceed the payslip amount plus payments in advance items/,
                   fn -> Repo.insert(payslip_payable) end
    end

    test "success" do
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

      salary_advance_category =
        insert(:payslip_category,
          org: org,
          code: "12",
          entry_type: :debit,
          description: "ADIANTAMENTO ANTERIOR"
        )

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_advance_category,
        amount: 400_00,
        is_payment_advance: true
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 600_00))

      salary_advance_payable =
        insert(:payable_bank_transfer, target: :payslip, org: org, amount: 400_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: salary_advance_payable,
        is_auto_adjustable_amount: false
      )

      salary_payable = insert(:payable_bank_transfer, target: :payslip, org: org, amount: 600_00)

      payslip_payable = %PayslipPayable{
        org_id: org.id,
        payslip_id: payslip.id,
        payable_id: salary_payable.id,
        is_auto_adjustable_amount: false
      }

      assert Repo.insert!(payslip_payable)
    end
  end
end
