defmodule Sig.DateTest do
  use Sig.DataCase

  describe "list_by_month/3" do
    test "returns a list of next dates by month" do
      assert Sig.Date.list_by_month(~D[2020-10-01], :next, 5) == [
               ~D[2020-11-01],
               ~D[2020-12-01],
               ~D[2021-01-01],
               ~D[2021-02-01],
               ~D[2021-03-01]
             ]

      assert Sig.Date.list_by_month(~D[2021-01-05], :next, 1) == [~D[2021-02-05]]
      assert Sig.Date.list_by_month(~D[2021-01-05], :next, 0) == []
    end

    test "returns a list of prior dates by month" do
      assert Sig.Date.list_by_month(~D[2021-03-15], :prior, 5) == [
               ~D[2021-02-15],
               ~D[2021-01-15],
               ~D[2020-12-15],
               ~D[2020-11-15],
               ~D[2020-10-15]
             ]

      assert Sig.Date.list_by_month(~D[2021-01-20], :prior, 1) == [~D[2020-12-20]]
      assert Sig.Date.list_by_month(~D[2021-01-20], :prior, 0) == []
    end

    test "when number_of_month is negative" do
      assert_raise ArgumentError,
                   "number_of_months cannot be negative",
                   fn -> Sig.Date.list_by_month(~D[2021-01-01], :next, -1) end
    end

    test "reurn the last date of the month when day doesn't exist in next or prior months" do
      assert Sig.Date.list_by_month(~D[2020-10-31], :next, 5) == [
               ~D[2020-11-30],
               ~D[2020-12-31],
               ~D[2021-01-31],
               ~D[2021-02-28],
               ~D[2021-03-31]
             ]
    end
  end

  describe "full_month?/2" do
    test "when is full month" do
      assert Sig.Date.full_month?(~D[2020-01-01], ~D[2020-01-31])
      assert Sig.Date.full_month?(~D[2020-02-01], ~D[2020-02-29])
    end

    test "when is not full month" do
      refute Sig.Date.full_month?(~D[2020-01-02], ~D[2020-01-31])
      refute Sig.Date.full_month?(~D[2020-02-01], ~D[2020-02-28])
    end
  end

  describe "next_month_start/0" do
    test "returns the first day of the next month" do
      assert Sig.Date.next_month_start() == Date.utc_today() |> Date.end_of_month() |> Date.add(1)
    end
  end

  describe "next_month_start/1" do
    test "returns the first day of the next month" do
      assert Sig.Date.next_month_start(Date.utc_today()) == Date.utc_today() |> Date.end_of_month() |> Date.add(1)
    end
  end

  describe "prior_month_start/0" do
    test "returns the first day of the last month" do
      assert Sig.Date.prior_month_start() ==
               Date.utc_today()
               |> Date.beginning_of_month()
               |> Date.add(-1)
               |> Date.beginning_of_month()
    end
  end

  describe "prior_month_start/1" do
    test "returns the first day of the last month" do
      assert Sig.Date.prior_month_start(Date.utc_today()) ==
               Date.utc_today()
               |> Date.beginning_of_month()
               |> Date.add(-1)
               |> Date.beginning_of_month()
    end
  end

  describe "get_max/2" do
    test "returns the max date" do
      assert Sig.Date.get_max(~D[2021-01-01], ~D[2021-01-02]) == ~D[2021-01-02]
      assert Sig.Date.get_max(~D[2021-01-02], ~D[2021-01-01]) == ~D[2021-01-02]
      assert Sig.Date.get_max(~D[2021-01-01], ~D[2021-01-01]) == ~D[2021-01-01]
      assert Sig.Date.get_max(nil, ~D[2021-01-01]) == ~D[2021-01-01]
      assert Sig.Date.get_max(~D[2021-01-01], nil) == ~D[2021-01-01]
    end
  end

  describe "get_min/2" do
    test "returns the max date" do
      assert Sig.Date.get_min(~D[2021-01-01], ~D[2021-01-02]) == ~D[2021-01-01]
      assert Sig.Date.get_min(~D[2021-01-02], ~D[2021-01-01]) == ~D[2021-01-01]
      assert Sig.Date.get_min(~D[2021-01-01], ~D[2021-01-01]) == ~D[2021-01-01]
      assert Sig.Date.get_min(nil, ~D[2021-01-01]) == ~D[2021-01-01]
      assert Sig.Date.get_min(~D[2021-01-01], nil) == ~D[2021-01-01]
    end
  end

  describe "nth_workday/2" do
    test "returns the nth workday of a month" do
      assert Sig.Date.nth_workday(~D[2021-10-01], 5) == ~D[2021-10-07]
      assert Sig.Date.nth_workday(~D[2021-10-15], 5) == ~D[2021-10-07]
      assert Sig.Date.nth_workday(~D[2021-11-01], 15) == ~D[2021-11-19]
      assert Sig.Date.nth_workday(~D[2022-02-01], 5) == ~D[2022-02-07]
    end
  end

  describe "adjust_for_workday/1" do
    test "returns the next work day when it is not a workday" do
      assert Sig.Date.adjust_for_workday(~D[2021-10-01]) == ~D[2021-10-01]
      assert Sig.Date.adjust_for_workday(~D[2021-10-31]) == ~D[2021-11-01]
      assert Sig.Date.adjust_for_workday(~D[2021-10-30]) == ~D[2021-11-01]
    end
  end
end
