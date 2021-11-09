defmodule Sig.Finance.Payables.PayableTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Payable

  describe "payables table base constraints" do
    test "org_id not_null_violation" do
      payable = %Payable{
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        is_fulfilled: false,
        method: :cash
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"payables\" violates not-null constraint/,
                   fn -> Repo.insert(payable) end
    end

    test "org_id foreign_key_constraint" do
      payable = %Payable{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        is_fulfilled: false,
        method: :cash
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "payables_amount_positive constraint" do
      org = insert(:org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: -1,
        description: Faker.Lorem.sentence(),
        is_fulfilled: false,
        method: :cash
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_amount_positive \(check_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "payables_reference_date_beginning_of_month constraint" do
      org = insert(:org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-15],
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        is_fulfilled: false,
        method: :cash
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_reference_date_beginning_of_month \(check_constraint\)/,
                   fn -> Repo.insert(payable) end
    end
  end

  describe "payables table payables_is_fulfilled_conditional constraints" do
    test "method is null" do
      org = insert(:org)
      user = insert(:user, org: org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        is_fulfilled: true,
        authorized_by_id: user.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_is_fulfilled_conditional \(check_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "authorized_by_id is null" do
      org = insert(:org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        is_fulfilled: true,
        method: :cash
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_is_fulfilled_conditional \(check_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "success" do
      org = insert(:org)
      user = insert(:user, org: org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        is_fulfilled: true,
        method: :cash,
        authorized_by_id: user.id
      }

      assert %Payable{} = Repo.insert!(payable)
    end
  end

  describe "payables table payables_method_conditional constraints when 'check'" do
    test "check_number is nil" do
      org = insert(:org)
      account = insert(:bank_account, org: org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        method: :check,
        check_bank_account_id: account.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_method_conditional \(check_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "check_bank_account_id is nil" do
      org = insert(:org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        method: :check,
        check_number: random_string_number()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_method_conditional \(check_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "check_bank_account_id foreign_key_constraint" do
      org = insert(:org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        method: :check,
        check_number: random_string_number(),
        check_bank_account_id: UUID.generate()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_check_bank_account_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "success" do
      org = insert(:org)
      account = insert(:bank_account, org: org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        method: :check,
        check_number: random_string_number(),
        check_bank_account_id: account.id
      }

      assert %Payable{} = Repo.insert!(payable)
    end
  end

  describe "payables table payables_method_conditional constraints when 'billet'" do
    test "billet_barcode is nil" do
      org = insert(:org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        method: :billet
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_method_conditional \(check_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "success" do
      org = insert(:org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert %Payable{} = Repo.insert!(payable)
    end
  end

  describe "payables table payables_method_conditional constraints when 'bank_transfer'" do
    test "credit_bank_account_id is nil" do
      org = insert(:org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        method: :bank_transfer
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_method_conditional \(check_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "credit_bank_account_id foreign_key_constraint" do
      org = insert(:org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        method: :bank_transfer,
        credit_bank_account_id: UUID.generate()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payables_credit_bank_account_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(payable) end
    end

    test "success" do
      org = insert(:org)
      account = insert(:bank_account, org: org)

      payable = %Payable{
        org: org,
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        method: :bank_transfer,
        credit_bank_account_id: account.id
      }

      assert %Payable{} = Repo.insert!(payable)
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence()
      }

      assert changeset = Payable.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               target: attrs[:target],
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               description: attrs[:description],
               note: attrs[:note]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        target: :invalid,
        due_date: :invalid,
        reference_date: :invalid,
        amount: :invalid,
        description: :invalid,
        note: :invalid
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               target: ["is invalid"],
               due_date: ["is invalid"],
               reference_date: ["is invalid"],
               amount: ["is invalid"],
               description: ["is invalid"],
               note: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = Payable.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               target: ["can't be blank"],
               due_date: ["can't be blank"],
               reference_date: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        is_fulfilled: true,
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence()
      }

      assert changeset = Payable.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               target: attrs[:target],
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               description: attrs[:description],
               note: attrs[:note]
             }
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: -1,
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence()
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than or equal to 0,00"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: String.duplicate("a", 256),
        note: String.duplicate("a", 256)
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["should be at most 255 character(s)"],
               note: ["should be at most 255 character(s)"]
             }
    end
  end

  describe "create_changeset/1 when 'check'" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :check,
        check_number: random_string_number(),
        check_bank_account_id: UUID.generate()
      }

      assert changeset = Payable.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               target: attrs[:target],
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               check_number: attrs[:check_number],
               check_bank_account_id: attrs[:check_bank_account_id]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :check,
        check_number: :invalid,
        check_bank_account_id: :invalid
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               check_number: ["is invalid"],
               check_bank_account_id: ["is invalid"]
             }
    end

    test "missing required attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :check
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               check_number: ["can't be blank"],
               check_bank_account_id: ["can't be blank"]
             }
    end

    test "check_bank_account assoc constraint" do
      org = insert(:org)

      attrs = %{
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :check,
        check_number: random_string_number(),
        check_bank_account_id: UUID.generate()
      }

      assert {:error, changeset} = attrs |> Payable.create_changeset() |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               check_bank_account: ["does not exist"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :check,
        check_number: String.duplicate("a", 256),
        check_bank_account_id: UUID.generate()
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               check_number: ["should be at most 255 character(s)"]
             }
    end
  end

  describe "create_changeset/1 when 'billet '" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert changeset = Payable.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               target: attrs[:target],
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               billet_barcode: attrs[:billet_barcode]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :billet,
        billet_barcode: :invalid
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               billet_barcode: ["is invalid"]
             }
    end

    test "missing required attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :billet
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               billet_barcode: ["can't be blank"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :billet,
        billet_barcode: String.duplicate("a", 256)
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               billet_barcode: ["should be at most 255 character(s)"]
             }
    end
  end

  describe "create_changeset/1 when 'bank_transfer'" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :bank_transfer,
        credit_bank_account_id: UUID.generate()
      }

      assert changeset = Payable.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               target: attrs[:target],
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               credit_bank_account_id: attrs[:credit_bank_account_id]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :bank_transfer,
        credit_bank_account_id: :invalid
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               credit_bank_account_id: ["is invalid"]
             }
    end

    test "missing required attrs" do
      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :bank_transfer
      }

      assert changeset = Payable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               credit_bank_account_id: ["can't be blank"]
             }
    end

    test "credit_bank_account assoc constraint" do
      org = insert(:org)

      attrs = %{
        org_id: org.id,
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :bank_transfer,
        credit_bank_account_id: UUID.generate()
      }

      assert {:error, changeset} = attrs |> Payable.create_changeset() |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               credit_bank_account: ["does not exist"]
             }
    end
  end

  describe "update_changest/2" do
    test "valid attrs" do
      payable = insert(:payable)

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 50_00,
        description: "Updated description",
        note: "Updated note",
        method: :cash
      }

      assert changeset = Payable.update_changeset(payable, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method]
             }
    end

    test "ignores non permitted attrs" do
      payable = insert(:payable_cash, target: :invoice)

      attrs = %{
        org_id: UUID.generate(),
        target: :payslip,
        is_fulfilled: true,
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 50_00,
        method: :check,
        description: "Updated description",
        check_number: random_string_number(),
        billet_barcode: random_string_number(),
        note: Faker.Lorem.sentence(),
        check_bank_account_id: UUID.generate(),
        credit_bank_account_id: UUID.generate(),
        authorized_by_id: UUID.generate()
      }

      assert changeset = Payable.update_changeset(payable, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               billet_barcode: attrs[:billet_barcode],
               check_bank_account_id: attrs[:check_bank_account_id],
               check_number: attrs[:check_number],
               credit_bank_account_id: attrs[:credit_bank_account_id]
             }
    end

    test "doesn't allow amount update when payable is_fulfilled" do
      org = insert(:org)
      user = insert(:user, org: org)

      payable =
        insert(:payable_cash,
          org: org,
          target: :payslip,
          is_fulfilled: true,
          authorized_by_id: user.id
        )

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 50_00,
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert changeset = Payable.update_changeset(payable, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["can't be changed when payable is fulfilled"]
             }
    end

    test "allow update for fulfilled payment when amount is not present" do
      org = insert(:org)
      user = insert(:user, org: org)

      payable =
        insert(:payable_cash,
          org: org,
          target: :payslip,
          is_fulfilled: true,
          authorized_by_id: user.id
        )

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert changeset = Payable.update_changeset(payable, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               billet_barcode: attrs[:billet_barcode]
             }
    end

    test "payables_validate_amount_sum_for_payslip_procedure when target is payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      payable = insert(:payable_cash, org: org, target: :payslip, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 200_00,
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) payables amount sum cannot exceed the payslip amount/,
                   fn -> payable |> Payable.update_changeset(attrs) |> Repo.update() end
    end

    test "when target is not a payslip" do
      org = insert(:org)
      payable = insert(:payable_cash, org: org, target: :invoice, amount: 100_00)

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number(),
        amount: 200_00
      }

      assert changeset = Payable.update_changeset(payable, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               billet_barcode: attrs[:billet_barcode],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end
  end

  describe "authorize_changeset/2" do
    test "valid attrs" do
      payable = insert(:payable)

      attrs = %{authorized_by_id: UUID.generate()}

      assert changeset = Payable.authorize_changeset(payable, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               authorized_by_id: attrs[:authorized_by_id]
             }
    end

    test "missing required attrs" do
      payable = insert(:payable)

      assert changeset = Payable.authorize_changeset(payable, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               authorized_by_id: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      payable = insert(:payable_cash)

      attrs = %{
        org_id: UUID.generate(),
        target: random_enum_value(:payable_target),
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: Enum.random(100_00..5_000_00),
        method: :cash,
        is_fulfilled: true,
        description: Faker.Lorem.sentence(),
        check_number: random_string_number(),
        billet_barcode: random_string_number(),
        note: Faker.Lorem.sentence(),
        check_bank_account_id: UUID.generate(),
        credit_bank_account_id: UUID.generate(),
        authorized_by_id: UUID.generate()
      }

      assert changeset = Payable.authorize_changeset(payable, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               authorized_by_id: attrs[:authorized_by_id]
             }
    end

    test "authorized_by assoc constraint" do
      payable = insert(:payable_cash)

      attrs = %{authorized_by_id: UUID.generate()}

      assert {:error, changeset} = payable |> Payable.authorize_changeset(attrs) |> Repo.update()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               authorized_by: ["does not exist"]
             }
    end
  end

  describe "unauthorize_changeset/2" do
    test "removes authorized_by_id" do
      org = insert(:org)
      user = insert(:user, org: org)
      payable = insert(:payable, org: org, authorized_by: user)

      assert changeset = Payable.unauthorize_changeset(payable)

      assert changeset.valid?

      assert changeset.changes == %{
               authorized_by_id: nil
             }
    end

    test "when authorized_by_id is nil" do
      payable = insert(:payable)

      assert changeset = Payable.unauthorize_changeset(payable)

      assert changeset.valid?

      assert changeset.changes == %{}
    end
  end
end
