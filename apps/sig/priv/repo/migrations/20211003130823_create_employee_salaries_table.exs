defmodule Sig.Repo.Migrations.CreateEmployeeSalariesTable do
  use Ecto.Migration

  def up do
    create table(:employee_salaries) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :start_date, :date, null: false
      add :amount, :integer, null: false

      timestamps()
    end

    create unique_index(
             :employee_salaries,
             [:start_date, :registration_id, :org_id],
             name: :employee_salaries_start_date
           )

    create constraint(
             :employee_salaries,
             :employee_salaries_amount_greater_than_zero,
             check: "amount > 0"
           )

    execute("""
      CREATE TRIGGER ensure_at_least_one_employee_salary_for_registration_on_delete
      AFTER DELETE ON employee_salaries
      FOR EACH ROW
      EXECUTE PROCEDURE ensure_at_least_one_resource_for_registration ();
    """)
  end

  def down do
    execute("""
      DROP TRIGGER ensure_at_least_one_employee_salary_for_registration_on_delete
      ON employee_salaries;
    """)

    drop constraint(
           :employee_salaries,
           :employee_salaries_amount_greater_than_zero
         )

    drop index(:employee_salaries, [:start_date, :registration_id, :org_id])

    drop table(:employee_salaries)
  end
end
