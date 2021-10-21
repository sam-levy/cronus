defmodule Sig.HR.Payslips do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Payslips.Create
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  defdelegate create(registration, attrs), to: Create, as: :call

  def create_change(%{} = attrs \\ %{}) do
    Payslip.create_changeset(attrs)
  end

  def list_by_registration(%Registration{} = registration) do
    registration
    |> query_by_registration()
    |> order_by(:start_date)
    |> Repo.all()
  end

  def get(%Registration{} = registration, id) when is_binary(id) do
    registration
    |> query_by_registration()
    |> where(id: ^id)
    |> Repo.one()
  end

  defp query_by_registration(registration) do
    Payslip
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end
end
