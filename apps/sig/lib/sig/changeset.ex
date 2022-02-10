defmodule Sig.Changeset do
  defmacro __using__(_) do
    quote do
      import Ecto.Changeset
      import Sig.Changeset
    end
  end

  import Ecto.Changeset

  alias Sig.Finance.Banks

  def validate_routing_number(changeset, field) do
    validate_change(
      changeset,
      field,
      fn field, routing_number ->
        if Banks.valid_routing_number?(routing_number) do
          []
        else
          [{field, "does not exist"}]
        end
      end
    )
  end

  def validate_required_if(
        changeset,
        conditional_field,
        conditional_field_value,
        fields_to_validate
      ) do
    case fetch_change(changeset, conditional_field) do
      {:ok, value} ->
        if value in List.wrap(conditional_field_value) do
          validate_required(changeset, List.wrap(fields_to_validate))
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  @date_comparison_dict %{lt: "before", eq: "equal to", gt: "after"}

  def validate_dates(%{valid?: true} = changeset, first_date_field, criteria, second_date_field) do
    criteria = List.wrap(criteria)

    with {_, first_date} when not is_nil(first_date) <-
           fetch_field(changeset, first_date_field),
         {_, second_date} when not is_nil(first_date) <-
           fetch_field(changeset, second_date_field),
         comparison <- Date.compare(first_date, second_date),
         true <- Enum.member?(criteria, comparison) do
      changeset
    else
      false ->
        criteria_string = join_criteria(criteria, @date_comparison_dict)

        add_error(changeset, first_date_field, "must be #{criteria_string} #{second_date_field}")

      _ ->
        changeset
    end
  end

  def validate_dates(changeset, _, _, _), do: changeset

  # TODO: Add test
  def validate_date(changeset, date_field, criteria, date, opts \\ [])

  def validate_date(%{valid?: true} = changeset, date_field, criteria, date, opts) do
    criteria = List.wrap(criteria)

    with {_, changeset_date} when not is_nil(changeset_date) <-
           fetch_field(changeset, date_field),
         comparison <- Date.compare(changeset_date, date),
         true <- Enum.member?(criteria, comparison) do
      changeset
    else
      false ->
        criteria_string = join_criteria(criteria, @date_comparison_dict)
        message = Keyword.get(opts, :target, Date.to_iso8601(date))

        add_error(changeset, date_field, "must be #{criteria_string} #{message}")

      _ ->
        changeset
    end
  end

  def validate_date(changeset, _, _, _, _), do: changeset

  def validate_numericality(changeset, field) do
    validate_format(changeset, field, ~r/^\d+$/)
  end

  @number_comparison_dict %{lt: "less than", eq: "equal to", gt: "greater than"}

  def validate_money(%{valid?: true} = changeset, field, criteria, value) do
    criteria = List.wrap(criteria)

    with {:ok, %Money{amount: amount}} <- fetch_change(changeset, field),
         comparison <- compare_numbers(amount, value),
         true <- Enum.member?(criteria, comparison) do
      changeset
    else
      false ->
        criteria_string = join_criteria(criteria, @number_comparison_dict)
        formatted_value = value |> Money.new() |> Money.to_string()

        add_error(changeset, field, "must be #{criteria_string} #{formatted_value}")

      _ ->
        changeset
    end
  end

  def validate_money(changeset, _, _, _), do: changeset

  defp join_criteria(criteria, dict) do
    criteria
    |> Enum.map(fn item -> Map.get(dict, item) end)
    |> Enum.join(" or ")
  end

  def drop_changes(changeset, fields_to_drop) do
    fields_to_drop
    |> List.wrap()
    |> Enum.reduce(changeset, fn field_to_drop, acc ->
      if Map.has_key?(changeset.changes, field_to_drop) do
        put_change(acc, field_to_drop, nil)
      else
        acc
      end
    end)
  end

  def drop_changes_if(
        %{valid?: true} = changeset,
        conditional_field,
        conditional_field_value,
        fields_to_drop
      ) do
    case fetch_change(changeset, conditional_field) do
      {:ok, value} when value == conditional_field_value ->
        drop_changes(changeset, fields_to_drop)

      _ ->
        changeset
    end
  end

  def drop_changes_if(changeset, _, _, _), do: changeset

  def copy_change_value(%{valid?: true} = changeset, from_field, to_field) do
    case fetch_change(changeset, from_field) do
      {:ok, value} -> put_change(changeset, to_field, value)
      :error -> raise(ArgumentError, "field #{from_field} not found")
    end
  end

  def copy_change_value(changeset, _, _), do: changeset

  def validate_is_active(%{valid?: true} = changeset, soft_delete_field) do
    case Map.get(changeset.data, soft_delete_field) do
      nil -> changeset
      _ -> add_error(changeset, soft_delete_field, "is already filled")
    end
  end

  def validate_is_active(changeset, _), do: changeset

  def validate_values_if(
        changeset,
        conditional_field,
        conditional_field_value,
        fields_to_validate
      )
      when is_list(fields_to_validate) do
    case fetch_change(changeset, conditional_field) do
      {:ok, value} when value == conditional_field_value ->
        Enum.reduce(fields_to_validate, changeset, fn {field, value}, acc ->
          case fetch_field(acc, field) do
            {_, ^value} ->
              acc

            _ ->
              add_error(
                acc,
                field,
                "must be #{value} when #{conditional_field} is #{conditional_field_value}"
              )
          end
        end)

      _ ->
        changeset
    end
  end

  def validate_non_empty_list(changeset, field) do
    case fetch_change(changeset, field) do
      {:ok, []} -> add_error(changeset, field, "list can't be empty")
      _ -> changeset
    end
  end

  # TODO: Add test
  def validate_beginning_of_month(%{valid?: true} = changeset, field) do
    case fetch_change(changeset, field) do
      {:ok, %Date{day: 1}} -> changeset
      {:ok, %Date{}} -> add_error(changeset, field, "must be first day of month")
      _ -> changeset
    end
  end

  def validate_beginning_of_month(changeset, _field), do: changeset

  # TODO: Add test
  def errors_to_string(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")
      "#{acc}#{k}: #{joined_errors}\n"
    end)
  end

  def add_timestamps(%{} = attrs) do
    attrs
    |> Map.put(:inserted_at, DateTime.utc_now())
    |> Map.put(:updated_at, DateTime.utc_now())
  end

  defp compare_numbers(num, num), do: :eq
  defp compare_numbers(first, second) when first < second, do: :lt
  defp compare_numbers(_first, _second), do: :gt
end
