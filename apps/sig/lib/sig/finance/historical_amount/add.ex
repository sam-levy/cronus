defmodule Sig.Finance.HistoricalAmount.Add do
  import Ecto.Changeset, only: [fetch_field: 2, put_embed: 3, add_error: 3]

  alias Sig.Finance.HistoricalAmount

  defmodule Context do
    defstruct status: :ok,
              changeset: nil,
              amount_field: nil,
              amount: nil,
              date_field: nil,
              date: nil,
              history_field: nil,
              history: nil
  end

  # TODO: Add tests
  def call(%{valid?: true} = changeset, amount_field, date_field, history_field) do
    %Context{
      changeset: changeset,
      amount_field: amount_field,
      date_field: date_field,
      history_field: history_field
    }
    |> set_history()
    |> set_date()
    |> set_amount()
    |> validate_historical_amount()
    |> handle_history()
    |> handle_return()
  end

  def call(changeset, _, _, _), do: changeset

  defp set_history(context) do
    %{changeset: changeset, history_field: history_field, amount_field: amount_field} = context

    case fetch_field(changeset, history_field) do
      {:data, history} ->
        %{context | history: history}

      {:changes, _} ->
        add_changeset_error(context, history_field, "cannot be directly manipulated")

      :error ->
        add_changeset_error(context, amount_field, "history field not found")
    end
  end

  defp set_date(%{status: :halted} = context), do: context

  defp set_date(context) do
    %{changeset: changeset, date_field: date_field} = context

    case fetch_field(changeset, date_field) do
      {_, date} -> %{context | date: date}
      :error -> add_changeset_error(context, date_field, "not found")
    end
  end

  defp set_amount(%{status: :halted} = context), do: context

  defp set_amount(context) do
    %{changeset: changeset, amount_field: amount_field} = context

    case fetch_field(changeset, amount_field) do
      {_, amount} -> %{context | amount: amount}
      :error -> add_changeset_error(context, amount_field, "not found")
    end
  end

  defp validate_historical_amount(%{status: :halted} = context), do: context

  defp validate_historical_amount(context) do
    %{date: date, date_field: date_field, amount: amount, amount_field: amount_field} = context

    attrs = %{date: date, amount: amount}

    case HistoricalAmount.changeset(attrs) do
      %{valid?: true, changes: %{date: date, amount: amount}} ->
        %{context | date: date, amount: amount}

      %{errors: errors} ->
        context
        |> map_errors_to_parent(errors, :date, date_field)
        |> map_errors_to_parent(errors, :amount, amount_field)
    end
  end

  defp map_errors_to_parent(context, errors, field, parent_field) do
    case Keyword.get(errors, field) do
      nil -> context
      field_errors -> add_changeset_error(context, parent_field, field_errors)
    end
  end

  defp handle_history(%{status: :halted} = context), do: context

  defp handle_history(%{history: []} = context), do: add_historical_amount(context)

  defp handle_history(%{history: [last_historical_amount | _]} = context) do
    %{date: date, date_field: date_field} = context

    case Date.compare(date, last_historical_amount.date) do
      :gt ->
        add_historical_amount(context)

      :eq ->
        update_last_historical_amount(context)

      :lt ->
        add_changeset_error(context, date_field, "must be greater than the last date in history")
    end
  end

  defp add_historical_amount(context) do
    %{
      changeset: changeset,
      date: date,
      amount: amount,
      history_field: history_field,
      history: history
    } = context

    new_historical_amount = %HistoricalAmount{date: date, amount: amount}

    %{context | changeset: put_embed(changeset, history_field, [new_historical_amount | history])}
  end

  defp update_last_historical_amount(context) do
    %{
      changeset: changeset,
      date: date,
      amount: amount,
      history_field: history_field,
      history: [last_historical_amount | history]
    } = context

    updated_historical_amount =
      HistoricalAmount.changeset(last_historical_amount, %{date: date, amount: amount})

    %{
      context
      | changeset: put_embed(changeset, history_field, [updated_historical_amount | history])
    }
  end

  defp add_changeset_error(context, field, error) do
    changeset = add_error(context.changeset, field, error)

    %{context | status: :halted, changeset: changeset}
  end

  defp handle_return(%{changeset: changeset}), do: changeset
end
