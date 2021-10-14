defmodule Sig.HR.Registrations.Vouchers do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Vouchers.Create
  alias Sig.HR.Registrations.Vouchers.Voucher
  alias Sig.Repo

  defdelegate create(registration, attrs), to: Create, as: :call

  def create_change(%{} = attrs \\ %{}), do: Voucher.create_changeset(attrs)

  def update_change(%Voucher{} = voucher, %{} = attrs \\ %{}) do
    Voucher.update_changeset(voucher, attrs)
  end

  def list_voucher_types do
    Voucher.VoucherType.__valid_values__() |> Enum.filter(&is_binary/1)
  end

  def get(%Registration{} = registration, id) when is_binary(id) do
    registration
    |> query_by_registration()
    |> where(id: ^id)
    |> Repo.one()
  end

  def list_by_registration(%Registration{} = registration, opts \\ []) do
    registration
    |> query_by_registration()
    |> order_by(:start_date)
    |> filter_by_types(opts)
    |> filter_by_in_effect_on_date(opts)
    |> Repo.all()
  end

  def update(%Voucher{} = voucher, %{} = attrs) do
    voucher
    |> Voucher.update_changeset(attrs)
    |> Repo.update()
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

  defp query_by_registration(registration) do
    Voucher
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end

  defp filter_by_types(query, opts) do
    case Keyword.get(opts, :types, :noop) do
      :noop -> query
      types -> where(query, [v], v.type in ^types)
    end
  end

  defp filter_by_in_effect_on_date(query, opts) do
    case Keyword.get(opts, :in_effect_on_date, :noop) do
      :noop ->
        query

      date ->
        query
        |> where([v], v.start_date <= ^date)
        |> where([v], is_nil(v.end_date) or v.end_date > ^date)
    end
  end
end
