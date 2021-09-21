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
end
