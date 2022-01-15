defmodule Sig.Finance.FinancialTransactions.CreatorTest do
  defmodule AttrsTest do
    use Sig.DataCase, async: true

    alias Sig.Finance.FinancialTransactions.Creator.Attrs

    describe "changeset/3" do
      test "valid attrs" do
        attrs = %{
          description: "Description",
          type: :bank_transfer,
          placement_date: ~D[2021-01-01],
          clearing_date: ~D[2021-01-01],
          payable_ids: [UUID.generate(), UUID.generate()],
          bank_account_id: UUID.generate()
        }

        assert changeset = Attrs.changeset(attrs)

        assert changeset.valid?

        assert changeset.changes == %{
                 description: attrs[:description],
                 type: attrs[:type],
                 placement_date: attrs[:placement_date],
                 clearing_date: attrs[:clearing_date],
                 payable_ids: attrs[:payable_ids],
                 bank_account_id: attrs[:bank_account_id]
               }
      end

      test "invalid attrs" do
        attrs = %{
          description: :invalid,
          type: :invalid,
          placement_date: :invalid,
          clearing_date: :invalid,
          payable_ids: :invalid,
          bank_account_id: :invalid
        }

        assert changeset = Attrs.changeset(attrs)

        refute changeset.valid?

        assert errors_on(changeset) == %{
                 type: ["is invalid"],
                 bank_account_id: ["is invalid"],
                 clearing_date: ["is invalid"],
                 description: ["is invalid"],
                 payable_ids: ["is invalid"],
                 placement_date: ["is invalid"]
               }
      end

      test "missing required attrs" do
        assert changeset = Attrs.changeset(%{})

        refute changeset.valid?

        assert errors_on(changeset) == %{
                 type: ["can't be blank"],
                 description: ["can't be blank"],
                 payable_ids: ["can't be blank"],
                 placement_date: ["can't be blank"]
               }
      end

      test "missing bank_account_id when type is bank type" do
        attrs = %{
          description: "Description",
          type: :billet,
          placement_date: ~D[2021-01-01],
          clearing_date: ~D[2021-01-02],
          payable_ids: [UUID.generate(), UUID.generate()]
        }

        assert changeset = Attrs.changeset(attrs)

        refute changeset.valid?

        assert errors_on(changeset) == %{
                 bank_account_id: ["can't be blank"]
               }
      end

      test "missing bank_account_id when type is NOT bank type" do
        attrs = %{
          description: "Description",
          type: :cash,
          placement_date: ~D[2021-01-01],
          clearing_date: ~D[2021-01-02],
          payable_ids: [UUID.generate()]
        }

        assert changeset = Attrs.changeset(attrs)

        assert changeset.valid?
      end

      test "string fields length greater than 255 chars" do
        attrs = %{
          description: String.duplicate("a", 256),
          type: :cash,
          placement_date: ~D[2021-01-01],
          clearing_date: ~D[2021-01-02],
          payable_ids: [UUID.generate(), UUID.generate()]
        }

        assert changeset = Attrs.changeset(attrs)

        refute changeset.valid?

        assert errors_on(changeset) == %{
                 description: ["should be at most 255 character(s)"]
               }
      end

      test "clearing_date before placement_date" do
        attrs = %{
          description: "Description",
          type: :cash,
          placement_date: ~D[2021-01-02],
          clearing_date: ~D[2021-01-01],
          payable_ids: [UUID.generate(), UUID.generate()]
        }

        assert changeset = Attrs.changeset(attrs)

        refute changeset.valid?

        assert errors_on(changeset) == %{
                 clearing_date: ["must be after or equal to placement_date"]
               }
      end

      test "payable_ids is empty" do
        attrs = %{
          description: "Description",
          type: :cash,
          placement_date: ~D[2021-01-01],
          clearing_date: ~D[2021-01-02],
          payable_ids: []
        }

        assert changeset = Attrs.changeset(attrs)

        refute changeset.valid?

        assert errors_on(changeset) == %{
                 payable_ids: ["list can't be empty"]
               }
      end
    end
  end

  use Sig.DataCase

  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Finance.FinancialTransactions.BankTransactions.BankTransaction
  alias Sig.Finance.FinancialTransactions.Creator
  alias Sig.Finance.Payables.Payable

  describe "pay_payables_change/3" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Creator.Attrs{}} = Creator.pay_payables_change()
    end
  end

  describe "pay_payables/2 with cash" do
    test "creates a financial transaction for a single payable for payslip" do
      org = insert(:org)
      user = insert(:user, org: org)

      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 1_000_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 1_000_00))

      payable =
        insert(:payable_cash,
          org: org,
          target: :payslip,
          authorized_by: user,
          amount: 1_000_00
        )

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      attrs = %{
        description: "Pagamento Fulano",
        type: :cash,
        placement_date: ~D[2022-01-01],
        clearing_date: ~D[2022-01-01],
        payable_ids: [payable.id]
      }

      assert {:ok, %FinancialTransaction{id: id}} = Creator.pay_payables(org, attrs)

      assert financial_transaction =
               Repo.get_by(FinancialTransaction,
                 id: id,
                 org_id: org.id,
                 entry_type: :debit,
                 amount: 1_000_00,
                 type: attrs[:type],
                 description: attrs[:description],
                 placement_date: attrs[:placement_date],
                 clearing_date: attrs[:clearing_date]
               )

      assert financial_transaction.transfer_counterparty_id == nil

      refute Repo.get_by(BankTransaction,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id
             )

      assert Repo.get_by(Payable,
               id: payable.id,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id
             )
    end
  end

  describe "pay_payables/2 with bank transaction" do
    test "creates a financial transaction for a single payable for payslip" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 1_000_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 1_000_00))

      payable =
        insert(:payable_bank_transfer,
          org: org,
          target: :payslip,
          authorized_by: user,
          amount: 1_000_00
        )

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      attrs = %{
        description: "Pagamento Fulano",
        type: :bank_transfer,
        placement_date: ~D[2022-01-01],
        clearing_date: ~D[2022-01-01],
        payable_ids: [payable.id],
        bank_account_id: bank_account.id
      }

      assert {:ok, %FinancialTransaction{id: id}} = Creator.pay_payables(org, attrs)

      assert financial_transaction =
               Repo.get_by(FinancialTransaction,
                 id: id,
                 org_id: org.id,
                 entry_type: :debit,
                 amount: 1_000_00,
                 type: attrs[:type],
                 description: attrs[:description],
                 placement_date: attrs[:placement_date],
                 clearing_date: attrs[:clearing_date]
               )

      assert financial_transaction.transfer_counterparty_id == nil

      assert Repo.get_by(BankTransaction,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id,
               bank_account_id: bank_account.id
             )

      assert Repo.get_by(Payable,
               id: payable.id,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id
             )
    end

    test "creates a financial transaction for multiple payables for payslip" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      payslip_1 = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip_1,
        entry_type: :credit,
        amount: 1_000_00
      )

      # Update payslip amount
      Repo.update!(change(payslip_1, amount: 1_000_00))

      payable_for_payslip_1 =
        insert(:payable_bank_transfer,
          org: org,
          target: :payslip,
          authorized_by: user,
          amount: 1_000_00
        )

      insert(:payslip_payable, org: org, payslip: payslip_1, payable: payable_for_payslip_1)

      payslip_2 = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip_2,
        entry_type: :credit,
        amount: 2_000_00
      )

      # Update payslip amount
      Repo.update!(change(payslip_2, amount: 2_000_00))

      payable_for_payslip_2 =
        insert(:payable_bank_transfer,
          org: org,
          target: :payslip,
          authorized_by: user,
          amount: 2_000_00
        )

      insert(:payslip_payable, org: org, payslip: payslip_2, payable: payable_for_payslip_2)

      attrs = %{
        description: "Pagamento de Funcionários",
        type: :bank_transfer,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable_for_payslip_1.id, payable_for_payslip_2.id],
        bank_account_id: bank_account.id
      }

      assert {:ok, %FinancialTransaction{id: id}} = Creator.pay_payables(org, attrs)

      assert financial_transaction =
               Repo.get_by(FinancialTransaction,
                 id: id,
                 org_id: org.id,
                 entry_type: :debit,
                 amount: 3_000_00,
                 type: attrs[:type],
                 description: attrs[:description],
                 placement_date: attrs[:placement_date]
               )

      assert financial_transaction.clearing_date == nil
      assert financial_transaction.transfer_counterparty_id == nil

      assert Repo.get_by(BankTransaction,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id,
               bank_account_id: bank_account.id
             )

      assert Repo.get_by(Payable,
               id: payable_for_payslip_1.id,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id
             )

      assert Repo.get_by(Payable,
               id: payable_for_payslip_2.id,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id
             )
    end

    # TODO: refactor when invoices are available
    test "creates a financial transaction for multiple payables for invoice" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      payable_1 =
        insert(:payable_billet, org: org, target: :invoice, amount: 100_00, authorized_by: user)

      payable_2 =
        insert(:payable_billet, org: org, target: :invoice, amount: 200_00, authorized_by: user)

      attrs = %{
        description: "Pagamento de Boletos",
        type: :billet,
        placement_date: ~D[2022-01-01],
        clearing_date: ~D[2022-01-02],
        payable_ids: [payable_1.id, payable_2.id],
        bank_account_id: bank_account.id
      }

      assert {:ok, %FinancialTransaction{id: id}} = Creator.pay_payables(org, attrs)

      assert financial_transaction =
               Repo.get_by(FinancialTransaction,
                 id: id,
                 org_id: org.id,
                 entry_type: :debit,
                 amount: 300_00,
                 type: attrs[:type],
                 description: attrs[:description],
                 placement_date: attrs[:placement_date],
                 clearing_date: attrs[:clearing_date]
               )

      assert financial_transaction.transfer_counterparty_id == nil

      assert Repo.get_by(BankTransaction,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id,
               bank_account_id: bank_account.id
             )

      assert Repo.get_by(Payable,
               id: payable_1.id,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id
             )

      assert Repo.get_by(Payable,
               id: payable_2.id,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id
             )
    end

    test "creates a financial transaction when type is check" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      payable =
        insert(:payable_check,
          org: org,
          amount: 100_00,
          authorized_by: user,
          check_debit_bank_account: bank_account
        )

      attrs = %{
        description: "Hortifruti",
        type: :check,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable.id],
        bank_account_id: bank_account.id
      }

      assert {:ok, %FinancialTransaction{id: id}} = Creator.pay_payables(org, attrs)

      assert financial_transaction =
               Repo.get_by(FinancialTransaction,
                 id: id,
                 org_id: org.id,
                 entry_type: :debit,
                 amount: 100_00,
                 type: attrs[:type],
                 description: attrs[:description],
                 placement_date: attrs[:placement_date]
               )

      assert financial_transaction.clearing_date == nil
      assert financial_transaction.transfer_counterparty_id == nil

      assert Repo.get_by(BankTransaction,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id,
               bank_account_id: bank_account.id
             )

      assert Repo.get_by(Payable,
               id: payable.id,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id
             )
    end

    test "returns error when payable is no found" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      payable = insert(:payable_bank_transfer, org: org, authorized_by: user)

      attrs = %{
        description: "Hortifruti",
        type: :bank_transfer,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable.id, UUID.generate()],
        bank_account_id: bank_account.id
      }

      assert {:error, "Existem pagáveis não encontrados"} = Creator.pay_payables(org, attrs)

      refute Repo.get_by(FinancialTransaction,
               org_id: org.id,
               entry_type: :debit,
               type: attrs[:type],
               description: attrs[:description],
               placement_date: attrs[:placement_date]
             )

      refute Repo.get_by(BankTransaction, org_id: org.id, bank_account_id: bank_account.id)

      assert payable = Repo.get_by(Payable, id: payable.id, org_id: org.id)
      assert payable.financial_transaction_id == nil
    end

    test "returns error when account is different form the acount in the check" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      payable = insert(:payable_check, org: org, authorized_by: user)

      attrs = %{
        description: "Hortifruti",
        type: :check,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable.id],
        bank_account_id: bank_account.id
      }

      assert {:error, "A conta bancária deve ser igual a do cheque"} =
               Creator.pay_payables(org, attrs)

      refute Repo.get_by(FinancialTransaction,
               org_id: org.id,
               entry_type: :debit,
               type: attrs[:type],
               description: attrs[:description],
               placement_date: attrs[:placement_date]
             )

      refute Repo.get_by(BankTransaction, org_id: org.id)

      assert payable = Repo.get_by(Payable, id: payable.id, org_id: org.id)
      assert payable.financial_transaction_id == nil
    end

    test "returns error for multiple payables when type is check" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      payable_1 =
        insert(:payable_check,
          org: org,
          authorized_by: user,
          check_debit_bank_account: bank_account
        )

      payable_2 =
        insert(:payable_check,
          org: org,
          authorized_by: user,
          check_debit_bank_account: bank_account
        )

      attrs = %{
        description: "Hortifruti",
        type: :check,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable_1.id, payable_2.id],
        bank_account_id: bank_account.id
      }

      assert {:error, "Não é possivel fazer pagamentos em lote de contas em cheque"} =
               Creator.pay_payables(org, attrs)

      refute Repo.get_by(FinancialTransaction,
               org_id: org.id,
               entry_type: :debit,
               type: attrs[:type],
               description: attrs[:description],
               placement_date: attrs[:placement_date]
             )

      refute Repo.get_by(BankTransaction, org_id: org.id, bank_account_id: bank_account.id)

      assert payable_1 = Repo.get_by(Payable, id: payable_1.id, org_id: org.id)
      assert payable_1.financial_transaction_id == nil

      assert payable_2 = Repo.get_by(Payable, id: payable_2.id, org_id: org.id)
      assert payable_2.financial_transaction_id == nil
    end

    test "returns error for multiple payables with different payment methods" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      payable_1 = insert(:payable_billet, org: org, authorized_by: user)
      payable_2 = insert(:payable_bank_transfer, org: org, authorized_by: user)

      attrs = %{
        description: "Hortifruti",
        type: :billet,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable_1.id, payable_2.id],
        bank_account_id: bank_account.id
      }

      assert {:error, "Existem pagáveis com métodos de pagamento diferentes"} =
               Creator.pay_payables(org, attrs)

      refute Repo.get_by(FinancialTransaction,
               org_id: org.id,
               entry_type: :debit,
               type: attrs[:type],
               description: attrs[:description],
               placement_date: attrs[:placement_date]
             )

      refute Repo.get_by(BankTransaction, org_id: org.id, bank_account_id: bank_account.id)

      assert payable_1 = Repo.get_by(Payable, id: payable_1.id, org_id: org.id)
      assert payable_1.financial_transaction_id == nil

      assert payable_2 = Repo.get_by(Payable, id: payable_2.id, org_id: org.id)
      assert payable_2.financial_transaction_id == nil
    end

    test "returns error when one payable is not authorized" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      payable_1 = insert(:payable_billet, org: org, authorized_by: user)
      payable_2 = insert(:payable_billet, org: org)

      attrs = %{
        description: "Hortifruti",
        type: :billet,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable_1.id, payable_2.id],
        bank_account_id: bank_account.id
      }

      assert {:error, "Existem pagáveis não autorizados"} = Creator.pay_payables(org, attrs)

      refute Repo.get_by(FinancialTransaction,
               org_id: org.id,
               entry_type: :debit,
               type: attrs[:type],
               description: attrs[:description],
               placement_date: attrs[:placement_date]
             )

      refute Repo.get_by(BankTransaction, org_id: org.id, bank_account_id: bank_account.id)

      assert payable_1 = Repo.get_by(Payable, id: payable_1.id, org_id: org.id)
      assert payable_1.financial_transaction_id == nil

      assert payable_2 = Repo.get_by(Payable, id: payable_2.id, org_id: org.id)
      assert payable_2.financial_transaction_id == nil
    end

    test "returns error when one payable is already paid" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: true)

      existing_financial_transaction =
        insert(:financial_transaction, org: org, entry_type: :debit, type: :billet, amount: 100_00)

      payable_1 = insert(:payable_billet, org: org, authorized_by: user)

      payable_2 =
        insert(:payable_billet,
          org: org,
          authorized_by: user,
          financial_transaction: existing_financial_transaction,
          amount: 100_00
        )

      attrs = %{
        description: "Hortifruti",
        type: :billet,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable_1.id, payable_2.id],
        bank_account_id: bank_account.id
      }

      assert {:error, "Existem pagáveis que já foram pagos"} = Creator.pay_payables(org, attrs)

      refute Repo.get_by(FinancialTransaction,
               org_id: org.id,
               entry_type: :debit,
               type: attrs[:type],
               description: attrs[:description],
               placement_date: attrs[:placement_date]
             )

      refute Repo.get_by(BankTransaction, org_id: org.id, bank_account_id: bank_account.id)

      assert payable_1 = Repo.get_by(Payable, id: payable_1.id, org_id: org.id)
      assert payable_1.financial_transaction_id == nil

      assert payable_2 = Repo.get_by(Payable, id: payable_2.id, org_id: org.id)
      assert payable_2.financial_transaction_id == existing_financial_transaction.id
    end

    test "returns error when bank account is not managed" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org, is_managed: false)

      payable = insert(:payable_billet, org: org, authorized_by: user)

      attrs = %{
        description: "Hortifruti",
        type: :billet,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable.id],
        bank_account_id: bank_account.id
      }

      assert {:error, "A conta não é administrada"} = Creator.pay_payables(org, attrs)

      refute Repo.get_by(FinancialTransaction,
               org_id: org.id,
               entry_type: :debit,
               type: attrs[:type],
               description: attrs[:description],
               placement_date: attrs[:placement_date]
             )

      refute Repo.get_by(BankTransaction, org_id: org.id, bank_account_id: bank_account.id)

      assert payable = Repo.get_by(Payable, id: payable.id, org_id: org.id)
      assert payable.financial_transaction_id == nil
    end

    test "returns error when bank account is not found" do
      org = insert(:org)
      user = insert(:user, org: org)
      payable = insert(:payable_billet, org: org, authorized_by: user)

      attrs = %{
        description: "Hortifruti",
        type: :billet,
        placement_date: ~D[2022-01-01],
        payable_ids: [payable.id],
        bank_account_id: UUID.generate()
      }

      assert {:error, "Conta não encontrada"} = Creator.pay_payables(org, attrs)

      refute Repo.get_by(FinancialTransaction,
               org_id: org.id,
               entry_type: :debit,
               type: attrs[:type],
               description: attrs[:description],
               placement_date: attrs[:placement_date]
             )

      refute Repo.get_by(BankTransaction, org_id: org.id)

      assert payable = Repo.get_by(Payable, id: payable.id, org_id: org.id)
      assert payable.financial_transaction_id == nil
    end

    test "returns changeset errors" do
      org = insert(:org)
      user = insert(:user, org: org)
      payable = insert(:payable_billet, org: org, authorized_by: user)

      attrs = %{
        type: "invalid",
        placement_date: :invalid,
        payable_ids: [],
        bank_account_id: "invalid"
      }

      assert {:error, changeset} = Creator.pay_payables(org, attrs)

      assert errors_on(changeset) == %{
               description: ["can't be blank"],
               type: ["is invalid"],
               placement_date: ["is invalid"],
               payable_ids: ["list can't be empty"],
               bank_account_id: ["is invalid"]
             }

      refute Repo.get_by(FinancialTransaction, org_id: org.id)
      refute Repo.get_by(BankTransaction, org_id: org.id)

      assert payable = Repo.get_by(Payable, id: payable.id, org_id: org.id)
      assert payable.financial_transaction_id == nil
    end
  end
end
