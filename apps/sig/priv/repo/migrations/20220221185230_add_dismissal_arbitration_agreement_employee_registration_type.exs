defmodule Sig.Repo.Migrations.AddDismissalArbitrationAgreementEmployeeRegistrationType do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    add_value_to_type(:employee_resignation_type, :dismissal_arbitration_agreement)
  end
end
