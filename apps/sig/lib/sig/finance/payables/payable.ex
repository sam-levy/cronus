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
    field :method, Sig.PaymentMethod
    field :description, :string
    field :check_number, :string
    field :billet_barcode, :string
    field :note, :string

    belongs_to :authorized_by, User
    belongs_to :check_bank_account, Account
    belongs_to :credit_bank_account, Account
    belongs_to :financial_transaction, FinancialTransaction

    has_one :payslip_payable, PayslipPayable

    timestamps()
  end

  @create_required_fields [:org_id, :target, :due_date, :reference_date]

  @optional_fields [
    :amount,
    :method,
    :description,
    :check_number,
    :billet_barcode,
    :note,
    :check_bank_account_id,
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
    |> validate_required_if(:method, :check, [:check_number, :check_bank_account_id])
    |> validate_required_if(:method, :billet, :billet_barcode)
    |> validate_required_if(:method, :bank_transfer, :credit_bank_account_id)
    |> validate_money(:amount, [:gt, :eq], 0)
    |> validate_length(:description, max: 255)
    |> validate_length(:check_number, max: 255)
    |> validate_length(:billet_barcode, max: 255)
    |> validate_length(:note, max: 255)
    |> assoc_constraint(:check_bank_account)
    |> assoc_constraint(:credit_bank_account)
    |> assoc_constraint(:financial_transaction)
  end

  # TODO: Add procedure to ensure payable is not fulfilled before delete or udpate amount
  # TODO: Add procedure to ensure payable amount is not changed when is fulfilled
end
