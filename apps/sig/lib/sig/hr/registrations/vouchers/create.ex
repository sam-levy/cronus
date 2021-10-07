defmodule Sig.HR.Registrations.Vouchers.Create do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Vouchers.Voucher
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok, attrs: nil, changeset: nil, registration: nil, result: nil
  end

  def call(%Registration{} = registration, %{} = attrs) do
    %Context{attrs: attrs, registration: registration}
    |> build_voucher_changeset()
    |> verify_existing_voucher()
    |> create_voucher()
    |> handle_result()
  end

  defp build_voucher_changeset(context) do
    %{registration: registration, attrs: attrs} = context

    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> Voucher.create_changeset()
    |> case do
      %{valid?: true} = changeset -> %{context | changeset: changeset}
      changeset -> put_error(context, changeset)
    end
  end

  defp verify_existing_voucher(%{status: :ok} = context) do
    %{attrs: %{type: type, start_date: start_date}, registration: registration} = context

    Voucher
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
    |> where(type: ^type)
    |> last(:start_date)
    |> Repo.one()
    |> do_verify_existing_voucher(start_date, context)
  end

  defp verify_existing_voucher(context), do: context

  defp do_verify_existing_voucher(nil, _start_date, context), do: context

  defp do_verify_existing_voucher(%{end_date: nil}, _start_date, context) do
    put_error(context, "existe um vale do mesmo tipo em vigência")
  end

  defp do_verify_existing_voucher(%{end_date: last_end_date}, start_date, context) do
    if Date.compare(start_date, last_end_date) == :lt do
      put_error(
        context,
        "a data de início deve ser posterior a data de término do último vale do mesmo tipo"
      )
    else
      context
    end
  end

  defp create_voucher(%{status: :ok} = context) do
    case Repo.insert(context.changeset) do
      {:ok, voucher} -> %{context | result: voucher}
      {:error, changeset} -> put_error(context, changeset)
    end
  end

  defp create_voucher(context), do: context

  defp put_error(context, error), do: %{context | status: {:error, error}}

  defp handle_result(%{status: {:error, error}}), do: {:error, error}
  defp handle_result(%{result: voucher}), do: {:ok, voucher}
end
