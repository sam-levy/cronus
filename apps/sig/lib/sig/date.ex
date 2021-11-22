defmodule Sig.Date do
  @type direction() :: :prior | :next

  @spec list_by_month(%Date{}, direction(), pos_integer()) :: [%Date{}]
  def list_by_month(%Date{day: day} = from_date, direction, number_of_months)
      when direction in [:prior, :next] and
             is_integer(number_of_months) and
             number_of_months > 0 do
    number_of_months
    |> build_range(direction)
    |> Enum.reduce(%{}, fn i, acc ->
      last_date = Map.get(acc, i - 1, from_date)

      Map.put(acc, i, build_date(direction, last_date, day))
    end)
    |> Map.values()
  end

  def list_by_month(%Date{}, direction, number_of_months)
      when direction in [:prior, :next] and
             is_integer(number_of_months) and
             number_of_months == 0 do
    []
  end

  def list_by_month(%Date{}, direction, number_of_months)
      when direction in [:prior, :next] and
             is_integer(number_of_months) and
             number_of_months < 0 do
    raise ArgumentError, "number_of_months cannot be negative"
  end

  defp build_range(number_of_months, :next), do: 1..number_of_months
  defp build_range(number_of_months, :prior), do: -number_of_months..-1

  defp build_date(:next, %Date{year: year, month: month}, day) when month < 12 do
    case Date.new(year, month + 1, day) do
      {:ok, date} -> date
      {:error, :invalid_date} -> Date.new!(year, month + 1, 1) |> Date.end_of_month()
    end
  end

  defp build_date(:next, %Date{year: year, month: _month}, day) do
    case Date.new(year + 1, 1, day) do
      {:ok, date} -> date
      {:error, :invalid_date} -> Date.new!(year + 1, 1, 1) |> Date.end_of_month()
    end
  end

  defp build_date(:prior, %Date{year: year, month: month}, day) when month > 1 do
    case Date.new(year, month - 1, day) do
      {:ok, date} -> date
      {:error, :invalid_date} -> Date.new!(year, month - 1, 1) |> Date.end_of_month()
    end
  end

  defp build_date(:prior, %Date{year: year, month: _month}, day) do
    case Date.new(year - 1, 12, day) do
      {:ok, date} -> date
      {:error, :invalid_date} -> Date.new!(year - 1, 12, 1) |> Date.end_of_month()
    end
  end

  def next_month_start, do: build_date(:next, Date.utc_today(), 1)
  def last_month_start, do: build_date(:prior, Date.utc_today(), 1)

  def nth_workday(date, days) do
    start_date = date |> Date.beginning_of_month() |> adjust_for_workday()

    Enum.reduce(1..(days - 1), start_date, fn
      _, acc -> acc |> Date.add(1) |> adjust_for_workday()
    end)
  end

  def prior_month_day_adjusted_for_workday(date, days) do
    date = build_date(:prior, date, 1)

    date
    |> Date.add(days - 1)
    |> adjust_for_workday()
  end

  defp adjust_for_workday(date) do
    case Date.day_of_week(date) do
      6 -> Date.add(date, 2)
      7 -> Date.add(date, 1)
      _ -> date
    end
  end
end
