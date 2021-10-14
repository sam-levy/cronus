defmodule Sig.HR.Registrations.Benefits.Create do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Benefits.Benefit
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok, attrs: nil, changeset: nil, registration: nil, result: nil
  end

  def call(%Registration{} = registration, %{} = attrs) do
    %Context{attrs: attrs, registration: registration}
    |> build_benefit_changeset()
    |> verify_existing_benefit()
    |> create_benefit()
    |> handle_result()
  end

  defp build_benefit_changeset(context) do
    %{registration: registration, attrs: attrs} = context

    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> Benefit.create_changeset()
    |> case do
      %{valid?: true} = changeset -> %{context | changeset: changeset}
      changeset -> put_error(context, changeset)
    end
  end

  defp verify_existing_benefit(%{status: :ok} = context) do
    %{attrs: %{type: type, start_date: start_date}, registration: registration} = context

    Benefit
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
    |> where(type: ^type)
    |> last(:start_date)
    |> Repo.one()
    |> do_verify_existing_benefit(start_date, context)
  end

  defp verify_existing_benefit(context), do: context

  defp do_verify_existing_benefit(nil, _start_date, context), do: context

  defp do_verify_existing_benefit(%{end_date: nil}, _start_date, context) do
    if context.attrs.is_for_dependent do
      context
    else
      put_error(context, "existe um vale do mesmo tipo em vigência")
    end
  end

  defp do_verify_existing_benefit(%{end_date: last_end_date}, start_date, context) do
    if not context.attrs.is_for_dependent and Date.compare(start_date, last_end_date) == :lt do
      put_error(
        context,
        "a data de início deve ser posterior a data de término do último vale do mesmo tipo"
      )
    else
      context
    end
  end

  defp create_benefit(%{status: :ok} = context) do
    case Repo.insert(context.changeset) do
      {:ok, benefit} -> %{context | result: benefit}
      {:error, changeset} -> put_error(context, changeset)
    end
  end

  defp create_benefit(context), do: context

  defp put_error(context, error), do: %{context | status: {:error, error}}

  defp handle_result(%{status: {:error, error}}), do: {:error, error}
  defp handle_result(%{result: benefit}), do: {:ok, benefit}
end
