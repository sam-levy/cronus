defmodule Sig.Repo.Migrations.CreateEmployeeBenefitsTable do
  use Ecto.Migration

  def change do
    create table(:employee_benefits) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :description, :string
      add :benefit_type, :employee_benefit_type
      add :benefit_amount, :integer
      add :benefit_amount_date, :date
      add :is_for_dependent, :boolean, null: false, default: false
      add :start_date, :date, null: false
      add :end_date, :date
      add :is_from_model, :boolean, null: false

      add :benefit_model_id,
          references(:employee_benefit_models,
            with: [org_id: :org_id],
            name: :employee_benefits_benefit_model
          )

      add :benefit_historical_amounts, {:array, :map}

      timestamps()
    end

    create constraint(
             :employee_benefits,
             :employee_benefits_amount_greater_than_zero,
             check: "benefit_amount > 0"
           )

    create constraint(
             :employee_benefits,
             :employee_benefits_start_date_before_end_date,
             check: "start_date < end_date"
           )

    create constraint(
             :employee_benefits,
             :employee_benefits_is_from_model_conditional,
             check: """
               CASE WHEN is_from_model = true THEN
                 benefit_amount IS NULL AND
                 benefit_amount_date IS NULL AND
                 benefit_historical_amounts IS NULL AND
                 benefit_type IS NULL AND
                 benefit_model_id IS NOT NULL
               ELSE
                 benefit_amount IS NOT NULL AND
                 benefit_amount_date IS NOT NULL AND
                 benefit_historical_amounts IS NOT NULL AND
                 benefit_type IS NOT NULL AND
                 benefit_model_id IS NULL
               END
             """
           )

    # TODO: Add trigger function to ensure the [type, end_date = nil]
    # uniqueness for benefits which `is_for_dependent` is false.

    # TODO: Add trigger function to ensure the period of benefits which
    # `is_for_dependent` is false do not overlap
  end
end
