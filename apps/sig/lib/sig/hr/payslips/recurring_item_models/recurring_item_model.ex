defmodule Sig.HR.Payslips.RecurringItemModels.RecurringItemModel do
  use Sig.Schema

  alias Sig.HR.Payslips.Categories.Category
  alias Sig.HR.Registrations.Vouchers.Voucher.VoucherType
  alias Sig.Organizations.Org

  defenum(PercentageTarget, :payslip_recurring_item_model_percentage_target, [
    :employee_salary,
    :employee_benefit
  ])

  schema "payslip_recurring_item_models" do
    belongs_to :org, Org, primary_key: true

    field :description, :string
    field :is_fixed_amount, :boolean

    field :amount, Money.Ecto.Amount.Type
    field :percentage, :integer
    field :percentage_target, PercentageTarget
    field :employee_benefit_type_percentage_target, VoucherType

    belongs_to :category, Category

    timestamps()
  end

  @create_base_required_fields [:org_id, :description, :is_fixed_amount, :category_id]

  @create_fields @create_base_required_fields ++
                   [
                     :amount,
                     :percentage,
                     :percentage_target,
                     :employee_benefit_type_percentage_target
                   ]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_base_required_fields)
    |> validate_length(:description, max: 255)
    |> unique_constraint([:description, :org_id])
    |> assoc_constraint(:category)
    |> handle_fixed_amount_changeset()
    |> handle_percentage_changeset()
  end

  defp handle_fixed_amount_changeset(
         %{valid?: true, changes: %{is_fixed_amount: true}} = changeset
       ) do
    changeset
    |> validate_required(:amount)
    |> validate_money(:amount, [:gt, :eq], 0)
    |> drop_changes([:percentage, :percentage_target, :employee_benefit_type_percentage_target])
  end

  defp handle_fixed_amount_changeset(changeset), do: changeset

  defp handle_percentage_changeset(
         %{valid?: true, changes: %{is_fixed_amount: false}} = changeset
       ) do
    changeset
    |> validate_required([:percentage, :percentage_target])
    |> validate_inclusion(:percentage, 0..100)
    |> validate_required_if(
      :percentage_target,
      :employee_benefit,
      :employee_benefit_type_percentage_target
    )
    |> drop_changes(:amount)
    |> drop_changes_if(
      :percentage_target,
      :employee_salary,
      :employee_benefit_type_percentage_target
    )
  end

  defp handle_percentage_changeset(changeset), do: changeset
end
