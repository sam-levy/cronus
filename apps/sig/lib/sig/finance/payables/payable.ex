defmodule Sig.Finance.Payables.Payable do
  use Sig.Schema

  alias Sig.Accounts.User
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.Organizations.Org

  defenum(PayableTarget, :payable_target, [:invoice, :payslip])

  schema "payables" do
    belongs_to :org, Org, primary_key: true

    field :target, PayableTarget
    field :due_date, :date
    field :reference_date, :date
    field :amount, Money.Ecto.Amount.Type
    field :financial_transaction_type, Sig.FinancialTransactionType
    field :description, :string
    field :check_number, :string
    field :billet_barcode, :string
    field :note, :string

    belongs_to :authorized_by, User
    belongs_to :check_debit_bank_account, Account
    belongs_to :credit_bank_account, Account
    belongs_to :financial_transaction, FinancialTransaction

    has_one :payslip_payable, PayslipPayable
    has_one :payslip, through: [:payslip_payable, :payslip]
    has_one :employee, through: [:payslip, :registration, :individual]
    has_one :employee_registration_company, through: [:payslip, :registration, :registered_at]

    timestamps()
  end

  @create_required_fields [:org_id, :target, :due_date, :reference_date]

  @optional_fields [
    :amount,
    :financial_transaction_type,
    :description,
    :check_number,
    :billet_barcode,
    :note,
    :check_debit_bank_account_id,
    :credit_bank_account_id
  ]

  @create_fields @create_required_fields ++ @optional_fields

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_required_fields)
    |> validate_fields()
  end

  @update_fields @optional_fields ++ [:due_date, :reference_date]

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @update_fields)
    |> validate_fields()
  end

  def authorize_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:authorized_by_id])
    |> validate_required([:authorized_by_id])
    |> assoc_constraint(:authorized_by)
  end

  def unauthorize_changeset(%__MODULE__{} = target) do
    target
    |> cast(%{}, [])
    |> put_change(:authorized_by_id, nil)
  end

  defp validate_fields(changeset) do
    changeset
    |> validate_required_if(:financial_transaction_type, :check, [
      :check_number,
      :check_debit_bank_account_id
    ])
    |> validate_required_if(:financial_transaction_type, :billet, :billet_barcode)
    |> validate_required_if(:financial_transaction_type, :bank_transfer, :credit_bank_account_id)
    |> validate_money(:amount, [:gt, :eq], 0)
    |> validate_length(:description, max: 255)
    |> validate_length(:check_number, max: 255)
    |> validate_length(:billet_barcode, max: 255)
    |> validate_length(:note, max: 255)
    |> assoc_constraint(:check_debit_bank_account)
    |> assoc_constraint(:credit_bank_account)
    |> assoc_constraint(:financial_transaction)
  end

  # TODO: Add procedure to ensure authorized_by_id is NULL before update and delete
end
