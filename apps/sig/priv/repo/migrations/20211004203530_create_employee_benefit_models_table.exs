defmodule Sig.Repo.Migrations.CreateEmployeeBenefitModelsTable do
  use Ecto.Migration

  def change do
    create table(:employee_benefit_models) do
      add :org_id, references(:orgs), primary_key: true

      add :description, :citext, null: false
      add :type, :employee_benefit_type, null: false
      add :amount, :integer, null: false
      add :amount_date, :date, null: false
      add :disabled_at, :date

      add :historical_amounts, {:array, :map}, default: []

      timestamps()
    end

    create unique_index(
             :employee_benefit_models,
             [:description, :org_id],
             name: :employee_benefit_models_unique_description
           )

    create constraint(
             :employee_benefit_models,
             :employee_benefit_models_amount_greater_than_zero,
             check: "amount > 0"
           )
  end
end
