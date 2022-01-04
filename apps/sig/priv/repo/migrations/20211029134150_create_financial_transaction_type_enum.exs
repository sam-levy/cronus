defmodule Sig.Repo.Migrations.CreateFinancialTransactionTypeEnum do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:financial_transaction_type, [
      :cash,
      :check,
      :billet,
      :bank_transfer
    ])
  end
end
