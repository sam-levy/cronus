defmodule Sig.Finance.PayablesTest do
  use Sig.DataCase

  alias Sig.Accounts.User
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips.Payslip

  describe "list/2" do
    test "lists payables ordered by `due_date`, `target` and `description`" do
      org = insert(:org)

      first_date = ~D[2022-01-01]
      second_date = ~D[2022-01-02]

      insert(:payable, org: org, due_date: second_date, target: :payslip, description: "B")
      insert(:payable, org: org, due_date: first_date, target: :payslip, description: "B")
      insert(:payable, org: org, due_date: second_date, target: :payslip, description: "A")
      insert(:payable, org: org, due_date: first_date, target: :payslip, description: "A")
      _payslip_payable_to_ignore = insert(:payable, target: :payslip)

      insert(:payable, org: org, due_date: second_date, target: :invoice, description: "B")
      insert(:payable, org: org, due_date: first_date, target: :invoice, description: "B")
      insert(:payable, org: org, due_date: second_date, target: :invoice, description: "A")
      insert(:payable, org: org, due_date: first_date, target: :invoice, description: "A")
      _invoice_payable_to_ignore = insert(:payable, target: :invoice)

      assert [
               %Payable{due_date: ^first_date, target: :invoice, description: "A"},
               %Payable{due_date: ^first_date, target: :invoice, description: "B"},
               %Payable{due_date: ^first_date, target: :payslip, description: "A"},
               %Payable{due_date: ^first_date, target: :payslip, description: "B"},
               %Payable{due_date: ^second_date, target: :invoice, description: "A"},
               %Payable{due_date: ^second_date, target: :invoice, description: "B"},
               %Payable{due_date: ^second_date, target: :payslip, description: "A"},
               %Payable{due_date: ^second_date, target: :payslip, description: "B"}
             ] = Payables.list(org)
    end

    test "filters by `due_date`" do
      org = insert(:org)

      first_date = ~D[2022-01-01]
      second_date = ~D[2022-01-02]

      insert(:payable, org: org, due_date: second_date, target: :payslip, description: "B")
      insert(:payable, org: org, due_date: first_date, target: :payslip, description: "B")
      insert(:payable, org: org, due_date: second_date, target: :payslip, description: "A")
      insert(:payable, org: org, due_date: first_date, target: :payslip, description: "A")

      _payslip_payable_to_ignore =
        insert(:payable, org: org, due_date: ~D[2022-01-03], target: :payslip)

      insert(:payable, org: org, due_date: second_date, target: :invoice, description: "B")
      insert(:payable, org: org, due_date: first_date, target: :invoice, description: "B")
      insert(:payable, org: org, due_date: second_date, target: :invoice, description: "A")
      insert(:payable, org: org, due_date: first_date, target: :invoice, description: "A")

      _invoice_payable_to_ignore =
        insert(:payable, org: org, due_date: ~D[2021-12-31], target: :invoice)

      opts = [due_date: [period_start: first_date, period_end: second_date]]

      assert [
               %Payable{due_date: ^first_date, target: :invoice, description: "A"},
               %Payable{due_date: ^first_date, target: :invoice, description: "B"},
               %Payable{due_date: ^first_date, target: :payslip, description: "A"},
               %Payable{due_date: ^first_date, target: :payslip, description: "B"},
               %Payable{due_date: ^second_date, target: :invoice, description: "A"},
               %Payable{due_date: ^second_date, target: :invoice, description: "B"},
               %Payable{due_date: ^second_date, target: :payslip, description: "A"},
               %Payable{due_date: ^second_date, target: :payslip, description: "B"}
             ] = Payables.list(org, opts)
    end

    test "filters by `payable_ids`" do
      org = insert(:org)
      date = ~D[2022-01-01]

      payable_a = insert(:payable, org: org, due_date: date, target: :invoice, description: "A")
      payable_b = insert(:payable, org: org, due_date: date, target: :invoice, description: "B")
      _payable_to_ignore = insert(:payable, org: org)

      opts = [payable_ids: [payable_a.id, payable_b.id]]

      assert [
               %Payable{description: "A"},
               %Payable{description: "B"},
             ] = Payables.list(org, opts)
    end

    test "filters authorized payables" do
      org = insert(:org)
      user = insert(:user, org: org)

      date = ~D[2022-01-01]

      insert(:payable, org: org, due_date: date, target: :invoice, description: "A", authorized_by: user)
      insert(:payable, org: org, due_date: date, target: :invoice, description: "B", authorized_by: user)
      _payable_to_ignore = insert(:payable, org: org)

      opts = [authorized_by: true]

      assert [
               %Payable{description: "A"},
               %Payable{description: "B"},
             ] = Payables.list(org, opts)
    end

    test "shallow preloads" do
      org = insert(:org)
      user = insert(:user, org: org)
      financial_transaction = insert(:financial_transaction, org: org)

      payable_a = insert(:payable_check,
        org: org,
        target: :payslip,
        due_date: ~D[2022-01-01],
        authorized_by: user,
        financial_transaction: financial_transaction,
        description: "A",
        amount: 0
      )

      insert(:payslip_payable, org: org, payable: payable_a)

      payable_b = insert(:payable_bank_transfer,
        org: org,
        target: :payslip,
        due_date: ~D[2022-01-01],
        authorized_by: user,
        financial_transaction: financial_transaction,
        description: "B",
        amount: 0
      )

      insert(:payslip_payable, org: org, payable: payable_b)

      opts = [
        preload: [
          :financial_transaction,
          :authorized_by,
          :check_debit_bank_account,
          :credit_bank_account,
          :payslip_payable,
          :payslip
        ]
      ]

      assert [
               %Payable{
                 financial_transaction: %FinancialTransaction{},
                 authorized_by: %User{},
                 check_debit_bank_account: %Account{},
                 payslip_payable: %PayslipPayable{},
                 payslip: %Payslip{}
               },
               %Payable{
                 financial_transaction: %FinancialTransaction{},
                 authorized_by: %User{},
                 credit_bank_account: %Account{},
                 payslip_payable: %PayslipPayable{},
                 payslip: %Payslip{}
               }
             ] = Payables.list(org, opts)
    end
  end
end
