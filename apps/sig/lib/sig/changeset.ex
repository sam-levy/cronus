defmodule Sig.Changeset do
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
      {:ok, value} when value == conditional_field_value ->
        validate_required(changeset, fields_to_validate)

      _ ->
        changeset
    end
  end

  def validate_first_date_before_second(changeset, first_date_field, second_date_field) do
    with {_, first_date} <- fetch_field(changeset, first_date_field),
         {:ok, second_date} <- fetch_change(changeset, second_date_field),
         :lt <- Date.compare(first_date, second_date) do
      changeset
    else
      :gt -> add_error(changeset, first_date_field, "cannot be after #{second_date_field}")
      _ -> changeset
    end
  end

  def validate_second_date_after_first(changeset, first_date_field, second_date_field) do
    with {_, first_date} <- fetch_field(changeset, first_date_field),
         {:ok, second_date} <- fetch_change(changeset, second_date_field),
         :lt <- Date.compare(first_date, second_date) do
      changeset
    else
      result when result in [:eq, :gt] -> add_error(changeset, second_date_field, "must be after #{first_date_field}")
      _ -> changeset
    end
  end

  @comparison_dict %{lt: "less than", eq: "equal to", gt: "greater than"}

  def validate_dates(%{valid?: true} = changeset, first_date_field, criteria, second_date_field) do
    criteria = List.wrap(criteria)

    with {_, first_date} <- fetch_field(changeset, first_date_field),
         {:ok, second_date} <- fetch_change(changeset, second_date_field),
         result <- Date.compare(first_date, second_date),
         true <- Enum.member?(criteria, result) do
      changeset
    else
      false ->
        criteria_message =
          criteria
          |> Enum.map(fn item -> Map.get(@comparison_dict, item) end)
          |> Enum.join(" or ")

        add_error(
          changeset,
          second_date_field,
          "#{first_date_field} must be #{criteria_message} #{second_date_field}"
        )

      _ ->
        changeset
    end
  end

  def validate_dates(changeset, _first_date_field, _criteria, _second_date_field), do: changeset

  def validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount > 0 -> []
      _, _ -> [amount: "must be greater than 0"]
    end)
  end

  def drop_change_if(
        changeset,
        conditional_field,
        conditional_field_value,
        field_to_drop
      ) do
    case fetch_field(changeset, conditional_field) do
      {_, value} when value == conditional_field_value ->
        put_change(changeset, field_to_drop, nil)

      _ ->
        changeset
    end
  end
end
