defmodule Sig.Repo.Migrations.BackfillEmployeeCompanyAssignmentsSectorId do
  use Ecto.Migration

  import Ecto.Query

  alias Sig.Repo

  @disable_migration_lock true
  @disable_ddl_transaction true

  def up do
    if should_backfill?() do
      Repo.transaction(
        fn ->
          registrations_query()
          |> Repo.all()
          |> Enum.each(fn registration ->
            Repo.update_all(
              from(ca in "employee_company_assignments",
                where:
                  ca.org_id == ^registration.org_id and ca.registration_id == ^registration.id
              ),
              set: [sector_id: registration.sector_id]
            )
          end)
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
        sector_id: r.sector_id
      }
    )
  end
end
