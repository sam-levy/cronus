defmodule Sig.Hour do
  import Ecto.Changeset, only: [fetch_change: 2, put_change: 3, validate_format: 3]

  def new, do: "00:00"

  def add(first, second) when is_binary(first) and is_binary(second) do
    with {:ok, first_tuple} <- to_tuple(first),
         {:ok, second_tuple} <- to_tuple(second) do
      add(first_tuple, second_tuple)
    else
      {:error, message} -> raise ArgumentError, message
    end
  end

  def add({first_hours, first_minuts}, {second_hours, second_minuts}) do
    {hours, minuts} = sum_minuts(first_minuts, second_minuts)

    stringify({first_hours + second_hours + hours, minuts})
  end

  def sum(hours) when is_list(hours), do: Enum.reduce(hours, new(), &add/2)

  @invalid_format_message "invalid format"

  defp to_tuple(hour_string) do
    with {:split, [hours, minuts]} <- {:split, String.split(hour_string, ":")},
         hours <- String.to_integer(hours),
         {:minuts, minuts} when minuts < 60 <- {:minuts, String.to_integer(minuts)} do
      {:ok, {hours, minuts}}
    else
      {:split, _} -> {:error, @invalid_format_message}
      {:minuts, _} -> {:error, "minuts must be less than 60"}
    end
  rescue
    _ -> {:error, @invalid_format_message}
  end

  defp sum_minuts(first, second) do
    case first + second do
      sum when sum < 60 -> {0, sum}
      sum when sum >= 60 -> {div(sum, 60), rem(sum, 60)}
    end
  end

  defp stringify({hours, minuts}), do: stringify(hours) <> ":" <> stringify(minuts)
  defp stringify(value) when value > 9, do: to_string(value)
  defp stringify(value), do: "0" <> to_string(value)

  defmodule Changeset do
    @format ~r/^[0-9]+:[0-5][0-9]$/

    @spec validate_hours(%Ecto.Changeset{}, atom()) :: %Ecto.Changeset{}
    def validate_hours(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
      with {:ok, hours} <- fetch_change(changeset, field),
           hours <- String.trim(hours),
           true <- String.match?(hours, @format) do
        put_change(changeset, field, hours)
      else
        false -> validate_format(changeset, field, @format)
        _ -> changeset
      end
    end
  end
end
