defmodule Sig.Repo.Migrations.BackfillRegistrationOrgPositions do
  use Ecto.Migration

  import Ecto.Query

  alias Ecto.UUID
  alias Sig.Repo

  @disable_migration_lock true
  @disable_ddl_transaction true

  def up do
    if should_backfill?() do
      Repo.transaction(
        fn ->
          registration_positions_attrs =
            registrations_query()
            |> Repo.all()
            |> Enum.map(&build_registration_position_attrs/1)

          Repo.insert_all("registration_org_positions", registration_positions_attrs)
        end,
        timeout: :infinity
      )
    end
  end

  def down do
  end

  defp should_backfill? do
    registrations_query()
    |> limit(1)
    |> Repo.exists?()
  end

  defp registrations_query do
    from(r in "employee_registrations",
      select: %{
        org_id: r.org_id,
        id: r.id,
        admission_date: r.admission_date,
        position_id: r.position_id,
        inserted_at: r.inserted_at
      }
    )
  end

  defp build_registration_position_attrs(registration) do
    %{
      org_id: registration.org_id,
      id: UUID.bingenerate(),
      registration_id: registration.id,
      start_date: registration.admission_date,
      position_id: registration.position_id,
      inserted_at: registration.inserted_at,
      updated_at: DateTime.utc_now()
    }
  end
end
