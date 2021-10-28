defmodule Sig.DateTest do
  use Sig.DataCase

  describe "list_by_month/3" do
    test "returns a list of next dates by month" do
      assert Sig.Date.list_by_month(~D[2021-01-01], :next, 3) == [
               ~D[2021-02-01],
               ~D[2021-03-01],
               ~D[2021-04-01]
             ]

      assert Sig.Date.list_by_month(~D[2021-01-05], :next, 1) == [~D[2021-02-05]]
      assert Sig.Date.list_by_month(~D[2021-01-05], :next, 0) == []
    end

    test "returns a list of prior dates by month" do
      assert Sig.Date.list_by_month(~D[2021-01-15], :prior, 4) == [
               ~D[2020-12-15],
               ~D[2020-11-15],
               ~D[2020-10-15],
               ~D[2020-09-15]
             ]

      assert Sig.Date.list_by_month(~D[2021-01-20], :prior, 1) == [~D[2020-12-20]]
      assert Sig.Date.list_by_month(~D[2021-01-20], :prior, 0) == []
    end

    test "when number_of_month is negative" do
      assert_raise ArgumentError,
                   "number_of_months cannot be negative",
                   fn -> Sig.Date.list_by_month(~D[2021-01-01], :next, -1) end
    end

    test "reurn the last date of the month when day doesn't exist in next months" do
      assert Sig.Date.list_by_month(~D[2021-01-31], :next, 4) == [
        ~D[2021-02-28],
        ~D[2021-03-31],
        ~D[2021-04-30],
        ~D[2021-05-31]
      ]
    end
  end

  describe "next_month_start/3" do
    test "returns the first day of the next month" do
      assert Sig.Date.next_month_start() == Date.utc_today() |> Date.end_of_month() |> Date.add(1)
    end
  end
end
