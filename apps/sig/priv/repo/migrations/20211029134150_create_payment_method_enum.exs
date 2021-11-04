defmodule Sig.Repo.Migrations.CreatePaymentMethodEnum do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:payment_method, [
      :cash,
      :check,
      :billet,
      :bank_transfer
    ])
  end
end
