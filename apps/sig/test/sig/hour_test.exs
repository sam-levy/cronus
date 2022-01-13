defmodule Sig.HourTest do
  use Sig.DataCase

  alias Sig.Hour

  describe "add/2" do
    test "sum hours" do
      assert Hour.add("01:00", "01:00") == "02:00"
      assert Hour.add("01:30", "01:00") == "02:30"
      assert Hour.add("01:35", "01:35") == "03:10"
      assert Hour.add("10:35", "10:35") == "21:10"
      assert Hour.add("200:35", "800:35") == "1001:10"
    end

    test "invalid format" do
      assert_raise ArgumentError,
                   "minuts must be less than 60",
                   fn -> Hour.add("01:60", "01:00") end

      assert_raise ArgumentError,
                   "invalid format",
                   fn -> Hour.add("0130", "01:00") end

      assert_raise ArgumentError,
                   "invalid format",
                   fn -> Hour.add("01:45", "0130") end

      assert_raise ArgumentError,
                   "invalid format",
                   fn -> Hour.add("01:45", "invalid") end
    end
  end

  describe "sum/2" do
    test "sum hours" do
      assert Hour.sum(["01:00", "01:00", "01:00"]) == "03:00"
      assert Hour.sum(["01:35", "01:35", "01:35"]) == "04:45"

      assert_raise ArgumentError,
                   "minuts must be less than 60",
                   fn -> Hour.sum(["01:35", "01:35", "01:60"]) end

      assert_raise ArgumentError,
                   "invalid format",
                   fn -> Hour.sum(["01:35", "invalid", "01:35"]) end
    end
  end

  describe "Changeset.validate_hours/2" do
    test "invalid format" do
      data = %{}
      types = %{hours_amount: :string}
      params = %{hours_amount: "invalid"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Hour.Changeset.validate_hours(:hours_amount)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               hours_amount: ["has invalid format"]
             }
    end

    test "valid format" do
      data = %{}
      types = %{hours_amount: :string}
      params = %{hours_amount: "01:30"}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Hour.Changeset.validate_hours(:hours_amount)

      assert changeset.valid?
    end

    test "trims trailing spaces" do
      data = %{}
      types = %{hours_amount: :string}
      params = %{hours_amount: "  01:30  "}

      changeset =
        {data, types}
        |> Ecto.Changeset.cast(params, Map.keys(types))
        |> Hour.Changeset.validate_hours(:hours_amount)

      assert changeset.valid?

      assert changeset.changes == %{
               hours_amount: "01:30"
             }
    end
  end
end
