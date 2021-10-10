defmodule Sig.HR.Registrations.Salaries.Salary do
  use Sig.Schema

  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  schema "employee_salaries" do
    belongs_to :org, Org, primary_key: true
    belongs_to :registration, Registration, primary_key: true

    field :start_date, :date
    field :amount, Money.Ecto.Amount.Type

    timestamps()
  end

  @fields [:org_id, :registration_id, :start_date, :amount]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_money(:amount, :gt, 0)
  end

  # TODO: Create a DB trigger with a stored procedure to
  # ensure that a registration always have at least one salary
end
