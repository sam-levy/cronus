defmodule Sig.Repo.Migrations.CreatePayslipRecurringItemModelsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:payslip_recurring_item_model_percentage_target, [
      :employee_salary,
      :employee_benefit
    ])

    create table(:payslip_recurring_item_models) do
      add :org_id, references(:orgs), primary_key: true

      add :description, :citext, null: false
      add :is_fixed_amount, :boolean, null: false

      add :amount, :integer
      add :percentage, :integer
      add :percentage_target, :payslip_recurring_item_model_percentage_target
      add :employee_benefit_type_percentage_target, :employee_benefit_type

      add :category_id, references(:payslip_categories, with: [org_id: :org_id]), null: false

      timestamps()
    end

    create unique_index(:payslip_recurring_item_models, [:description, :org_id])

    create constraint(
             :payslip_recurring_item_models,
             :payslip_recurring_item_models_positive_amount,
             check: "amount >= 0"
           )

    create constraint(
             :payslip_recurring_item_models,
             :payslip_recurring_item_models_percentage_range,
             check: "percentage BETWEEN 0 AND 100"
           )

    create constraint(
             :payslip_recurring_item_models,
             :payslip_recurring_item_models_fixed_amount_conditional,
             check: """
               CASE WHEN is_fixed_amount = true THEN
                 amount IS NOT NULL AND
                 percentage IS NULL AND
                 percentage_target IS NULL AND
                 employee_benefit_type_percentage_target IS NULL
               ELSE
                 amount IS NULL AND
                 percentage IS NOT NULL AND
                 percentage_target IS NOT NULL
               END
             """
           )

    create constraint(
             :payslip_recurring_item_models,
             :payslip_recurring_item_models_percentage_target_conditional,
             check: """
               CASE
                 WHEN percentage_target = 'employee_salary'
                   THEN employee_benefit_type_percentage_target IS NULL
                 WHEN percentage_target = 'employee_benefit'
                   THEN employee_benefit_type_percentage_target IS NOT NULL
               END
             """
           )
  end
end
