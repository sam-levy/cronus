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
end
