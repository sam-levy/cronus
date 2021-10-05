defmodule Sig.HR.Registrations.Vouchers do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Vouchers.Create
  alias Sig.HR.Registrations.Vouchers.Voucher
  alias Sig.Repo

  defdelegate create(registration, attrs), to: Create, as: :call

  def create_change(%{} = attrs \\ %{}) do
    Voucher.create_changeset(attrs)
  end

  def list_by_registration(%Registration{} = registration) do
    Voucher
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
    |> order_by(:start_date)
    |> Repo.all
  end

  def subscribe_to_registration_vouchers(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(registration))
  end

  def broadcast_registration_vouchers(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(registration),
      {:updated_registration_vouchers, list_by_registration(registration)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":vouchers"
  end
end
