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
