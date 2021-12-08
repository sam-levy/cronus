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

  def full_month?(start_date, end_date) do
    start_date == Date.beginning_of_month(start_date) and
      end_date == Date.end_of_month(end_date)
  end

  def next_month_start, do: build_date(:next, Date.utc_today(), 1)
  def next_month_start(date), do: build_date(:next, date, 1)

  def prior_month_start, do: build_date(:prior, Date.utc_today(), 1)
  def prior_month_start(date), do: build_date(:prior, date, 1)

  def get_max(%Date{} = first, %Date{} = second) do
    if Date.compare(first, second) == :gt, do: first, else: second
  end

  def get_max(first, second), do: get_date(first, second)

  def get_min(%Date{} = first, %Date{} = second) do
    if Date.compare(first, second) == :lt, do: first, else: second
  end

  def get_min(first, second), do: get_date(first, second)

  defp get_date(nil, %Date{} = second), do: second
  defp get_date(%Date{} = first, nil), do: first

  def nth_workday(date, days) do
    start_date = date |> Date.beginning_of_month() |> adjust_for_workday()

    Enum.reduce(1..(days - 1), start_date, fn
      _, acc -> acc |> Date.add(1) |> adjust_for_workday()
    end)
  end

  def adjust_for_workday(date) do
    case Date.day_of_week(date) do
      6 -> Date.add(date, 2)
      7 -> Date.add(date, 1)
      _ -> date
    end
  end
end
