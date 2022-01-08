defmodule Sig.ChangesetTest do
  use Sig.DataCase

  describe "validate_routing_number/2" do
    test "valid routing number" do
      data = %{}
      types = %{routing_number: :string}
      params = %{routing_number: random_bank_routing_number()}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_routing_number(:routing_number)

      assert changeset.valid?
    end

    test "invalid routing number" do
      data = %{}
      types = %{routing_number: :string}
      params = %{routing_number: "invalid"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_routing_number(:routing_number)

      refute changeset.valid?
      assert errors_on(changeset) == %{routing_number: ["does not exist"]}
    end
  end

  describe "validate_required_if/4" do
    test "when meets condition and fields are present" do
      data = %{}
      types = %{is_joint_account_holder: :boolean, relationship_with_holder: :string}
      params = %{is_joint_account_holder: false, relationship_with_holder: "child"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_required_if(:is_joint_account_holder, false, [
          :relationship_with_holder
        ])

      assert changeset.valid?
    end

    test "when meets condition in a list and fields are present" do
      data = %{}
      types = %{pokemon: :string, relationship_with_holder: :string}
      params = %{pokemon: "snorlex", relationship_with_holder: "child"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_required_if(:pokemon, ["snorlex", "blastoise"], [
          :relationship_with_holder
        ])

      assert changeset.valid?
    end

    test "when meets condition and fields are not present" do
      data = %{}
      types = %{is_joint_account_holder: :boolean, relationship_with_holder: :string}
      params = %{is_joint_account_holder: false}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_required_if(:is_joint_account_holder, false, [
          :relationship_with_holder
        ])

      refute changeset.valid?
      assert errors_on(changeset) == %{relationship_with_holder: ["can't be blank"]}
    end

    test "when meets condition in a list and fields are not present" do
      data = %{}
      types = %{pokemon: :string, relationship_with_holder: :string}
      params = %{pokemon: "snorlex"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_required_if(:pokemon, ["snorlex", "blastoise"], [
          :relationship_with_holder
        ])

      refute changeset.valid?
      assert errors_on(changeset) == %{relationship_with_holder: ["can't be blank"]}
    end

    test "ignores if condition is not met" do
      data = %{}
      types = %{is_joint_account_holder: :boolean, relationship_with_holder: :string}
      params = %{is_joint_account_holder: true}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_required_if(:is_joint_account_holder, false, [
          :relationship_with_holder
        ])

      assert changeset.valid?
    end

    test "ignores if condition is not met when list" do
      data = %{}
      types = %{pokemon: :string, relationship_with_holder: :string}
      params = %{pokemon: "charmander"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_required_if(:pokemon, ["snorlex", "blastoise"], [
          :relationship_with_holder
        ])

      assert changeset.valid?
    end

    test "accepts an atom as field to validate" do
      data = %{}
      types = %{is_joint_account_holder: :boolean, relationship_with_holder: :string}
      params = %{is_joint_account_holder: false, relationship_with_holder: "child"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_required_if(
          :is_joint_account_holder,
          false,
          :relationship_with_holder
        )

      assert changeset.valid?
    end
  end

  describe "validate_dates/4" do
    test "skips when first_date is nil" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: nil, second_date: ~D[2021-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, :lt, :second_date)

      assert changeset.valid?
    end

    test "skips when second_date is nil" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2020-01-01], second_date: nil}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, :lt, :second_date)

      assert changeset.valid?
    end

    test "skips when both dates are nil" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: nil, second_date: nil}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, :lt, :second_date)

      assert changeset.valid?
    end

    test ":lt true" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2020-01-01], second_date: ~D[2021-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, :lt, :second_date)

      assert changeset.valid?
    end

    test ":lt false" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2021-01-01], second_date: ~D[2020-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, :lt, :second_date)

      refute changeset.valid?

      assert errors_on(changeset) == %{first_date: ["must be before second_date"]}
    end

    test ":eq true" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2021-01-01], second_date: ~D[2021-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, :eq, :second_date)

      assert changeset.valid?
    end

    test ":eq false" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2021-01-01], second_date: ~D[2020-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, :eq, :second_date)

      refute changeset.valid?

      assert errors_on(changeset) == %{first_date: ["must be equal to second_date"]}
    end

    test ":gt true" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2021-01-01], second_date: ~D[2020-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, :gt, :second_date)

      assert changeset.valid?
    end

    test ":gt false" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2020-01-01], second_date: ~D[2021-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, :gt, :second_date)

      refute changeset.valid?

      assert errors_on(changeset) == %{first_date: ["must be after second_date"]}
    end

    test "[:lt, :eq] true when :lt" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2020-01-01], second_date: ~D[2021-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, [:lt, :eq], :second_date)

      assert changeset.valid?
    end

    test "[:lt, :eq] true when :eq" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2021-01-01], second_date: ~D[2021-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, [:lt, :eq], :second_date)

      assert changeset.valid?
    end

    test "[:lt, :eq] false when :gt" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2021-01-01], second_date: ~D[2020-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, [:lt, :eq], :second_date)

      refute changeset.valid?

      assert errors_on(changeset) == %{first_date: ["must be before or equal to second_date"]}
    end

    test "[:eq, :gt] true when :eq" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2021-01-01], second_date: ~D[2021-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, [:eq, :gt], :second_date)

      assert changeset.valid?
    end

    test "[:eq, :gt] true when :gt" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2021-01-01], second_date: ~D[2020-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, [:eq, :gt], :second_date)

      assert changeset.valid?
    end

    test "[:eq, :gt] false when :lt" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2020-01-01], second_date: ~D[2021-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_dates(:first_date, [:eq, :gt], :second_date)

      refute changeset.valid?

      assert errors_on(changeset) == %{first_date: ["must be equal to or after second_date"]}
    end
  end

  describe "validate_money/2" do
    test ":gt true" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(1_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, :gt, 1_000_00)

      assert changeset.valid?
    end

    test ":gt false" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(1_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, :gt, 1_500_00)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than 1.500,00"]
             }
    end

    test ":eq true" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(1_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, :eq, 1_500_00)

      assert changeset.valid?
    end

    test ":eq false" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(1_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, :eq, 2_000_00)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be equal to 2.000,00"]
             }
    end

    test ":lt true" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(1_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, :lt, 2_000_00)

      assert changeset.valid?
    end

    test ":lt false" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(2_000_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, :lt, 2_000_00)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be less than 2.000,00"]
             }
    end

    test "[:lt, :eq] true when :lt" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(1_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, [:lt, :eq], 2_000_00)

      assert changeset.valid?
    end

    test "[:lt, :eq] true when :eq" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(1_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, [:lt, :eq], 1_500_00)

      assert changeset.valid?
    end

    test "[:lt, :eq] false when :gt" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(2_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, [:lt, :eq], 2_000_00)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be less than or equal to 2.000,00"]
             }
    end

    test "[:eq, :gt] true when :eq" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(2_000_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, [:lt, :eq], 2_000_00)

      assert changeset.valid?
    end

    test "[:eq, :gt] true when :gt" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(2_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, [:eq, :gt], 2_000_00)

      assert changeset.valid?
    end

    test "[:eq, :gt] false when :lt" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(1_500_00)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount, [:eq, :gt], 2_000_00)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be equal to or greater than 2.000,00"]
             }
    end
  end

  describe "drop_changes/4" do
    test "drops fields from changeset" do
      data = %{}

      types = %{
        is_joint_account_holder: :boolean,
        relationship_with_holder: :string,
        other: :string
      }

      params = %{is_joint_account_holder: true, relationship_with_holder: "child", other: "test"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.drop_changes([:relationship_with_holder, :other])

      assert changeset.valid?

      assert changeset.changes == %{is_joint_account_holder: true}
    end

    test "when fields are not present in changeset changes" do
      data = %{}

      types = %{
        is_joint_account_holder: :boolean
      }

      params = %{is_joint_account_holder: true}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.drop_changes([:not_present, :another_not_present])

      assert changeset.valid?

      assert changeset.changes == %{is_joint_account_holder: true}
    end

    test "accepts an atom as field" do
      data = %{}
      types = %{is_joint_account_holder: :boolean, relationship_with_holder: :string}
      params = %{is_joint_account_holder: true, relationship_with_holder: "child"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.drop_changes(:relationship_with_holder)

      assert changeset.valid?

      assert changeset.changes == %{is_joint_account_holder: true}
    end
  end

  describe "drop_changes_if/4" do
    test "drops fields if condition is met" do
      data = %{}

      types = %{
        is_joint_account_holder: :boolean,
        relationship_with_holder: :string,
        other: :string
      }

      params = %{is_joint_account_holder: true, relationship_with_holder: "child", other: "test"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.drop_changes_if(:is_joint_account_holder, true, [
          :relationship_with_holder,
          :other
        ])

      assert changeset.valid?

      assert changeset.changes == %{is_joint_account_holder: true}
    end

    test "keeps fields if condition is not met" do
      data = %{}

      types = %{
        is_joint_account_holder: :boolean,
        relationship_with_holder: :string,
        other: :string
      }

      params = %{is_joint_account_holder: false, relationship_with_holder: "child", other: "test"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.drop_changes_if(:is_joint_account_holder, true, [
          :relationship_with_holder,
          :other
        ])

      assert changeset.valid?

      assert changeset.changes == %{
               is_joint_account_holder: false,
               relationship_with_holder: "child",
               other: "test"
             }
    end

    test "accepts an atom as field" do
      data = %{}
      types = %{is_joint_account_holder: :boolean, relationship_with_holder: :string}
      params = %{is_joint_account_holder: true, relationship_with_holder: "child"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.drop_changes_if(
          :is_joint_account_holder,
          true,
          :relationship_with_holder
        )

      assert changeset.valid?

      assert changeset.changes == %{is_joint_account_holder: true}
    end
  end

  describe "copy_change_value/3" do
    test "copy a value from a field in change to another" do
      data = %{}
      types = %{start_date: :integer, benefit_amount_date: :integer}
      params = %{start_date: 10, benefit_amount_date: nil}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.copy_change_value(:start_date, :benefit_amount_date)

      assert changeset.valid?

      assert changeset.changes == %{start_date: 10, benefit_amount_date: 10}
    end

    test "raises when source field doesn't exist" do
      data = %{}
      types = %{start_date: :integer, benefit_amount_date: :integer}
      params = %{start_date: 10, benefit_amount_date: nil}

      assert_raise ArgumentError,
                   ~r/field inexistent not found/,
                   fn ->
                     {data, types}
                     |> Ecto.Changeset.cast(params, Map.keys(types))
                     |> Sig.Changeset.copy_change_value(:inexistent, :benefit_amount_date)
                   end
    end

    test "raises when target field doesn't exist" do
      data = %{}
      types = %{start_date: :integer, benefit_amount_date: :integer}
      params = %{start_date: 10, benefit_amount_date: nil}

      assert_raise ArgumentError,
                   ~r/unknown field `:inexistent` in %{}/,
                   fn ->
                     {data, types}
                     |> Ecto.Changeset.cast(params, Map.keys(types))
                     |> Sig.Changeset.copy_change_value(:start_date, :inexistent)
                   end
    end
  end

  describe "validate_is_active/2" do
    test "validate a data field is nil" do
      data = %{end_date: nil}
      types = %{end_date: :date}
      params = %{}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_is_active(:end_date)

      assert changeset.valid?
    end

    test "when field is not nil" do
      data = %{end_date: ~D[2020-01-01]}
      types = %{end_date: :date}
      params = %{}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_is_active(:end_date)

      refute changeset.valid?

      assert errors_on(changeset) == %{end_date: ["is already filled"]}
    end
  end

  describe "validate_values_if/1" do
    test "when data entry type is debit" do
      data = %{entry_type: :debit}
      types = %{entry_type: Sig.EntryType, is_payment_advance: :boolean}
      params = %{is_payment_advance: true}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_values_if(:is_payment_advance, true, entry_type: :debit)

      assert changeset.valid?
    end

    test "when params entry type is debit" do
      data = %{}
      types = %{entry_type: Sig.EntryType, is_payment_advance: :boolean}
      params = %{entry_type: :debit, is_payment_advance: true}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_values_if(:is_payment_advance, true, entry_type: :debit)

      assert changeset.valid?
    end

    test "when data entry type is credit" do
      data = %{entry_type: :credit}
      types = %{entry_type: Sig.EntryType, is_payment_advance: :boolean}
      params = %{is_payment_advance: true}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_values_if(:is_payment_advance, true, entry_type: :debit)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entry_type: ["must be debit when is_payment_advance is true"]
             }
    end

    test "when params entry type is credit" do
      data = %{}
      types = %{entry_type: Sig.EntryType, is_payment_advance: :boolean}
      params = %{entry_type: :credit, is_payment_advance: true}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_values_if(:is_payment_advance, true, entry_type: :debit)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entry_type: ["must be debit when is_payment_advance is true"]
             }
    end

    test "one invalid field when more than one field" do
      data = %{}
      types = %{entry_type: Sig.EntryType, is_payment_advance: :boolean, other_field: :string}
      params = %{is_payment_advance: true, entry_type: :credit, other_field: "value"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_values_if(:is_payment_advance, true,
          entry_type: :debit,
          other_field: "value"
        )

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entry_type: ["must be debit when is_payment_advance is true"]
             }
    end

    test "more than one invalid field" do
      data = %{}
      types = %{entry_type: Sig.EntryType, is_payment_advance: :boolean, other_field: :string}
      params = %{is_payment_advance: true, entry_type: :credit, other_field: "invalid"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_values_if(:is_payment_advance, true,
          entry_type: :debit,
          other_field: "valid"
        )

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entry_type: ["must be debit when is_payment_advance is true"],
               other_field: ["must be valid when is_payment_advance is true"]
             }
    end
  end

  describe "validate_non_empty_list/1" do
    test "when list is empty" do
      data = %{entry_type: :debit}
      types = %{payable_ids: {:array, UUID}}
      params = %{payable_ids: []}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_non_empty_list(:payable_ids)

      refute changeset.valid?

      assert errors_on(changeset) == %{payable_ids: ["list can't be empty"]}
    end

    test "when list is not empty" do
      data = %{entry_type: :debit}
      types = %{payable_ids: {:array, UUID}}
      params = %{payable_ids: [UUID.generate()]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_non_empty_list(:payable_ids)

      assert changeset.valid?
    end
  end

  describe "add_timestamps/1" do
    test "adds timestmaps" do
      assert %{inserted_at: %DateTime{}, updated_at: %DateTime{}} =
               Sig.Changeset.add_timestamps(%{})
    end
  end
end
