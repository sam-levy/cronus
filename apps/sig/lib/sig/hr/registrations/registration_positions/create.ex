defmodule Sig.HR.Registrations.RegistrationPositions.Create do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RegistrationPositions.RegistrationPosition
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok, attrs: nil, changeset: nil, registration: nil, result: nil
  end

  def call(%Registration{} = registration, %{} = attrs) do
    %Context{attrs: attrs, registration: registration}
    |> build_registration_position_changeset()
    |> validate_start_date()
    |> create_registration_position()
    |> handle_result()
  end

  defp build_registration_position_changeset(context) do
    %{registration: registration, attrs: attrs} = context

    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> RegistrationPosition.create_changeset()
    |> case do
      %{valid?: true} = changeset -> %{context | changeset: changeset}
      changeset -> put_error(context, changeset)
    end
  end

  defp validate_start_date(%{status: :ok} = context) do
    %{attrs: %{start_date: start_date}, registration: registration} = context

    RegistrationPosition
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
    |> last(:start_date)
    |> Repo.one()
    |> do_validate_satart_date(start_date, context)
  end

  defp validate_start_date(context), do: context

  defp do_validate_satart_date(nil, _start_date, context), do: context

  defp do_validate_satart_date(
         %RegistrationPosition{start_date: last_start_date},
         start_date,
         context
       ) do
    if Date.compare(last_start_date, start_date) == :lt do
      context
    else
      put_error(context, "a data de início deve ser posterior a data de início da última posição")
    end
  end

  defp create_registration_position(%{status: :ok} = context) do
    case Repo.insert(context.changeset) do
      {:ok, registration_position} -> %{context | result: registration_position}
      {:error, changeset} -> put_error(context, changeset)
    end
  end

  defp create_registration_position(context), do: context

  defp put_error(context, error), do: %{context | status: {:error, error}}

  defp handle_result(%{status: {:error, error}}), do: {:error, error}
  defp handle_result(%{result: registration_position}), do: {:ok, registration_position}
end
