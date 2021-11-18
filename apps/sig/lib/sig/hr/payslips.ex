defmodule Sig.HR.Payslips do
  import Ecto.Query

  alias Sig.HR.Payslips.CreateFromModel
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Payslips.Create
  alias Sig.HR.Payslips.Delete
  alias Sig.HR.Payslips.Payslip
  alias Sig.Organizations
  alias Sig.Repo

  defdelegate create(registration, attrs), to: Create, as: :call

  defdelegate create_from_model(registration, attrs, opts \\ []),
    to: CreateFromModel,
    as: :call

  defdelegate delete(payslip), to: Delete, as: :call

  def create_change(%{} = attrs \\ %{}) do
    Payslip.create_changeset(attrs)
  end

  def list_by_registration(%Registration{} = registration) do
    registration
    |> query_by_registration()
    |> order_by(desc: :start_date)
    |> Repo.all()
  end

  def get(%Registration{} = registration, id) when is_binary(id) do
    registration
    |> query_by_registration()
    |> where(id: ^id)
    |> Organizations.preload_org()
    |> Repo.one()
  end

  def get_by(attrs), do: Repo.get_by(Payslip, attrs)

  def update_payslip_amount(%Payslip{} = payslip, items) when is_list(items) do
    items
    |> Enum.filter(&(&1.payslip_id == payslip.id))
    |> calculate_amount()
    |> case do
      %Money{amount: amount} when amount < 0 ->
        {:error, "payslip amount can't be negative"}

      %Money{amount: amount} when amount == payslip.amount.amount ->
        {:ok, payslip}

      %Money{amount: amount} ->
        payslip
        |> Payslip.update_amount_changeset(%{amount: amount})
        |> Repo.update()
    end
  end

  defp calculate_amount(items) do
    Money.subtract(Sig.sum_by(:credit, items), Sig.sum_by(:debit, items))
  end

  def subscribe_to_registration_payslips(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, registration_payslips_topic(registration))
  end

  def broadcast_registration_payslips(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      registration_payslips_topic(registration),
      {:updated_registration_payslips, list_by_registration(registration)}
    )
  end

  def broadcast_deleted_registration_payslip(%Registration{} = registration, %Payslip{} = payslip) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      registration_payslips_topic(registration),
      {:deleted_payslip, payslip}
    )
  end

  def subscribe_to_payslip(%Payslip{} = payslip) do
    Phoenix.PubSub.subscribe(Sig.PubSub, payslip_topic(payslip))
  end

  def unsubscribe_from_payslip(%Payslip{} = payslip) do
    Phoenix.PubSub.unsubscribe(Sig.PubSub, payslip_topic(payslip))
  end

  def broadcast_payslip_update(%Payslip{} = payslip) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      payslip_topic(payslip),
      {:updated_payslip, Repo.get_by(Payslip, org_id: payslip.org_id, id: payslip.id)}
    )
  end

  defp registration_payslips_topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":payslips"
  end

  defp payslip_topic(%Payslip{} = payslip), do: "payslip_id:" <> payslip.id

  defp query_by_registration(registration) do
    Payslip
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end
end
