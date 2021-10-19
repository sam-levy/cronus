defmodule Sig.Repo do
  use Ecto.Repo,
    otp_app: :sig,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Changeset, only: [add_error: 3, apply_action: 2]

  defoverridable insert: 2, update: 2

  def insert(%Ecto.Changeset{} = changeset, opts) do
    super(changeset, opts)
  rescue
    exception in Postgrex.Error ->
      handle_postgrex_exception(exception, __STACKTRACE__, changeset, :insert)
  end

  def insert(schema, opts), do: super(schema, opts)

  def update(changeset, opts) do
    super(changeset, opts)
  rescue
    exception in Postgrex.Error ->
      handle_postgrex_exception(exception, __STACKTRACE__, changeset, :update)
  end

  defp handle_postgrex_exception(
         %{
           postgres: %{
             code: :integrity_constraint_violation,
             message: "start_date before or equal to an existing record end_date"
           }
         },
         _,
         changeset,
         action
       ) do
    changeset
    |> add_error(:start_date, "cannot be before or equal to an existing record end_date")
    |> apply_action(action)
  end

  defp handle_postgrex_exception(
         %{
           postgres: %{
             code: :integrity_constraint_violation,
             message: "end_date after or equal to an existing record start_date"
           }
         },
         _,
         changeset,
         action
       ) do
    changeset
    |> add_error(:end_date, "cannot be after or equal to an existing record start_date")
    |> apply_action(action)
  end

  defp handle_postgrex_exception(exception, stacktrace, _, _), do: reraise(exception, stacktrace)
end
