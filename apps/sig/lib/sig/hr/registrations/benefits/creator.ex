defmodule Sig.HR.Registrations.Benefits.Creator do
  alias Sig.HR.BenefitModels
  alias Sig.HR.Registrations.Benefits
  alias Sig.HR.Registrations.Benefits.Benefit
  alias Sig.HR.Registrations.Registration
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              is_from_model: nil,
              benefit_model: nil,
              attrs: nil,
              changeset: nil,
              registration: nil,
              result: nil
  end

  def create(%Registration{} = registration, %{} = attrs) do
    %Context{is_from_model: false, attrs: attrs, registration: registration} |> do_create()
  end

  def create_from_model(%Registration{} = registration, %{} = attrs) do
    %Context{is_from_model: true, attrs: attrs, registration: registration} |> do_create()
  end

  defp do_create(context) do
    context
    |> set_attrs_primary_keys()
    |> build_benefit_changeset()
    |> fetch_benefit_model()
    |> verify_existing_benefit()
    |> create_benefit()
    |> handle_result()
  end

  defp set_attrs_primary_keys(%{attrs: attrs, registration: registration} = context) do
    attrs =
      attrs
      |> Map.put(:org_id, registration.org_id)
      |> Map.put(:registration_id, registration.id)

    %{context | attrs: attrs}
  end

  defp build_benefit_changeset(%{is_from_model: false, attrs: attrs} = context) do
    attrs
    |> Benefit.create_changeset()
    |> handle_changeset(context)
  end

  defp build_benefit_changeset(%{is_from_model: true, attrs: attrs} = context) do
    attrs
    |> Benefit.create_from_model_changeset()
    |> handle_changeset(context)
  end

  defp handle_changeset(%{valid?: true} = changeset, context) do
    %{context | changeset: changeset}
  end

  defp handle_changeset(changeset, context), do: put_error(context, changeset)

  defp fetch_benefit_model(%{status: :ok, is_from_model: true} = context) do
    %{registration: %{org: org}, attrs: %{benefit_model_id: benefit_model_id}} = context

    case BenefitModels.get(org, benefit_model_id) do
      nil -> put_error(context, "benefit model not found")
      benefit_model -> %{context | benefit_model: benefit_model}
    end
  end

  defp fetch_benefit_model(context), do: context

  defp verify_existing_benefit(%{status: :ok, is_from_model: false} = context) do
    %{attrs: %{benefit_type: benefit_type}, registration: registration} = context

    registration
    |> Benefits.list_by_registration(types: [benefit_type], last_by: :start_date)
    |> do_verify_existing_benefit(context)
  end

  defp verify_existing_benefit(%{status: :ok, is_from_model: true} = context) do
    %{benefit_model: %{type: type}, registration: registration} = context

    registration
    |> Benefits.list_by_registration(types: [type], last_by: :start_date)
    |> do_verify_existing_benefit(context)
  end

  defp verify_existing_benefit(context), do: context

  defp do_verify_existing_benefit([%{is_for_dependent: false, end_date: nil}], context) do
    if context.attrs.is_for_dependent do
      context
    else
      put_error(context, "existe um benefício do mesmo tipo em vigência")
    end
  end

  defp do_verify_existing_benefit([%{is_for_dependent: false, end_date: last_end_date}], context) do
    %{attrs: %{is_for_dependent: is_for_dependent, start_date: start_date}} = context

    if not is_for_dependent and Date.compare(start_date, last_end_date) == :lt do
      put_error(
        context,
        "a data de início deve ser posterior a data de término do último benefício do mesmo tipo"
      )
    else
      context
    end
  end

  defp do_verify_existing_benefit(_return, context), do: context

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
