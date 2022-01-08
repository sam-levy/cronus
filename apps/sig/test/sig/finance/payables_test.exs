defmodule Sig.Finance.PayablesTest do
  use Sig.DataCase

  alias Sig.Accounts.User
  alias Sig.Entities.Individuals.Individual
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips.Payslip

  describe "get/3" do
    test "returns a payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)
      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 0)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      assert %Payable{id: ^id} = Payables.get(payslip, id)
    end

    test "preloads authorized_by" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)
      %{id: user_id} = user = insert(:user, org: org)

      %{id: payable_id} =
        payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 0, authorized_by: user)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      assert %Payable{id: ^payable_id, authorized_by: %User{id: ^user_id}} =
               Payables.get(payslip, payable_id, preload: :authorized_by)
    end

    test "when payable belongs to another payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)
      another_payslip = insert(:payslip, org: org, amount: 0)

      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 0)
      insert(:payslip_payable, org: org, payslip: another_payslip, payable: payable)

      assert Payables.get(payslip, id) == nil
    end

    test "when payable doesn't exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)

      assert Payables.get(payslip, UUID.generate()) == nil
    end
  end

  describe "list_by/2 Org" do
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
             ] = Payables.list_by(org)
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
             ] = Payables.list_by(org, opts)
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
               %Payable{description: "B"}
             ] = Payables.list_by(org, opts)
    end

    test "filters authorized payables" do
      org = insert(:org)
      user = insert(:user, org: org)

      date = ~D[2022-01-01]

      insert(:payable,
        org: org,
        due_date: date,
        target: :invoice,
        description: "A",
        authorized_by: user
      )

      insert(:payable,
        org: org,
        due_date: date,
        target: :invoice,
        description: "B",
        authorized_by: user
      )

      _ignore = insert(:payable, org: org)

      assert [
               %Payable{description: "A"},
               %Payable{description: "B"}
             ] = Payables.list_by(org, authorized: true)
    end

    test "filters non authorized payables" do
      org = insert(:org)
      user = insert(:user, org: org)

      date = ~D[2022-01-01]

      insert(:payable,
        org: org,
        due_date: date,
        target: :invoice,
        description: "A"
      )

      insert(:payable,
        org: org,
        due_date: date,
        target: :invoice,
        description: "B"
      )

      _ignore = insert(:payable, org: org, authorized_by: user)

      assert [
               %Payable{description: "A"},
               %Payable{description: "B"}
             ] = Payables.list_by(org, authorized: false)
    end

    test "shallow preloads" do
      org = insert(:org)
      user = insert(:user, org: org)
      financial_transaction = insert(:financial_transaction, org: org)

      payable_a =
        insert(:payable_check,
          org: org,
          target: :payslip,
          due_date: ~D[2022-01-01],
          authorized_by: user,
          financial_transaction: financial_transaction,
          description: "A",
          amount: 0
        )

      insert(:payslip_payable, org: org, payable: payable_a)

      payable_b =
        insert(:payable_bank_transfer,
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
          :payslip,
          :employee
        ]
      ]

      assert [
               %Payable{
                 financial_transaction: %FinancialTransaction{},
                 authorized_by: %User{},
                 check_debit_bank_account: %Account{},
                 payslip_payable: %PayslipPayable{},
                 payslip: %Payslip{},
                 employee: %Individual{}
               },
               %Payable{
                 financial_transaction: %FinancialTransaction{},
                 authorized_by: %User{},
                 credit_bank_account: %Account{},
                 payslip_payable: %PayslipPayable{},
                 payslip: %Payslip{},
                 employee: %Individual{}
               }
             ] = Payables.list_by(org, opts)
    end
  end

  describe "list_by/2 Payslip" do
    test "lists payables from a payslip ordered by due_date" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      payable_billet =
        insert(:payable_billet,
          org: org,
          target: :payslip,
          due_date: ~D[2021-07-05],
          amount: 100_00
        )

      payable_cash =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-06-20], amount: 100_00)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_cash)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_billet)

      # To ignore
      from_another_payslip =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: from_another_payslip)

      # To ignore
      from_another_org =
        insert(:payable_cash, target: :payslip, due_date: ~D[2021-09-01], amount: 0)

      insert(:payslip_payable, org: from_another_org.org, payable: from_another_org)

      assert [
               %Payable{due_date: ~D[2021-06-20]},
               %Payable{due_date: ~D[2021-07-05]}
             ] = Payables.list_by(payslip)
    end

    test "preloads" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      payable_cash =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-06-20], amount: 200_00)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_cash)

      assert [
               %Payable{payslip_payable: %PayslipPayable{}}
             ] = Payables.list_by(payslip)
    end

    test "when payslip has no payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      # To ignore
      from_another_payslip =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: from_another_payslip)

      assert Payables.list_by(payslip) == []
    end
  end
end
