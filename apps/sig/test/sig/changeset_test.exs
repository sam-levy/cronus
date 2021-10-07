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

  describe "validate_first_date_before_second/4" do
    test "when first date is before second date" do
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
    test "when amount is greater than 0" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(1_500_00, :BRL)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount)

      assert changeset.valid?
    end

    test "when amount is 0" do
      data = %{}
      types = %{amount: Money.Ecto.Amount.Type}
      params = %{amount: Money.new(0, :BRL)}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_money(:amount)

      refute changeset.valid?
    end
  end

  describe "drop_change_if/4" do
    test "drops field if condition is met" do
      data = %{}
      types = %{is_joint_account_holder: :boolean, relationship_with_holder: :string}
      params = %{is_joint_account_holder: true, relationship_with_holder: "child"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.drop_change_if(:is_joint_account_holder, true, :relationship_with_holder)

      assert changeset.valid?

      assert changeset.changes == %{is_joint_account_holder: true}
    end

    test "keeps field if condition is not met" do
      data = %{}
      types = %{is_joint_account_holder: :boolean, relationship_with_holder: :string}
      params = %{is_joint_account_holder: false, relationship_with_holder: "child"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.drop_change_if(:is_joint_account_holder, true, :relationship_with_holder)

      assert changeset.valid?

      assert changeset.changes == %{
               is_joint_account_holder: false,
               relationship_with_holder: "child"
             }
    end
  end
end
