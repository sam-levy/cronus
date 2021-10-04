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

  describe "validate_first_date_before_second/4" do
    test "when first date is before second date" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2020-01-01], second_date: ~D[2021-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_first_date_before_second(:first_date, :second_date)

      assert changeset.valid?
    end

    test "when first date is after second date" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2021-01-01], second_date: ~D[2020-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_first_date_before_second(:first_date, :second_date)

      refute changeset.valid?

      assert errors_on(changeset) == %{first_date: ["cannot be after second_date"]}
    end

    test "when first date is nil" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: nil, second_date: ~D[2020-01-01]}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_first_date_before_second(:first_date, :second_date)

      assert changeset.valid?
    end

    test "when second date is nil" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: ~D[2020-01-01], second_date: nil}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_first_date_before_second(:first_date, :second_date)

      assert changeset.valid?
    end

    test "when both dates are nil" do
      data = %{}
      types = %{first_date: :date, second_date: :date}
      params = %{first_date: nil, second_date: nil}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Sig.Changeset.validate_first_date_before_second(:first_date, :second_date)

      assert changeset.valid?
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
