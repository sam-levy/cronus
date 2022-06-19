defmodule Sig.HR.Registrations.Benefits.Creator do
  alias Sig.HR.BenefitModels
  alias Sig.HR.Registrations.Benefits
  alias Sig.HR.Registrations.Benefits.Benefit
  alias Sig.HR.Registrations.Registration
  alias Sig.Repo

  def create(%Registration{} = registration, %{} = attrs),
    do: do_create(%{is_from_model: false, attrs: attrs, registration: registration})

  def create_from_model(%Registration{} = registration, %{} = attrs),
    do: do_create(%{is_from_model: true, attrs: attrs, registration: registration})

  defp do_create(context) do
    context
    |> Extep.new()
    |> Extep.run(&set_attrs_primary_keys/1, :attrs)
    |> Extep.run(&build_benefit_changeset/1, :changeset)
    |> Extep.run(&fetch_benefit_model/1, :benefit_model)
    |> Extep.run(&validate_existing_benefit/1)
    |> Extep.return(&Repo.insert(&1.changeset))
  end

  defp set_attrs_primary_keys(%{attrs: attrs, registration: registration}) do
    attrs =
      attrs
      |> Map.put(:org_id, registration.org_id)
      |> Map.put(:registration_id, registration.id)

    {:ok, attrs}
  end

  defp build_benefit_changeset(%{is_from_model: false, attrs: attrs}) do
    attrs
    |> Benefit.create_changeset()
    |> handle_changeset()
  end

  defp build_benefit_changeset(%{is_from_model: true, attrs: attrs}) do
    attrs
    |> Benefit.create_from_model_changeset()
    |> handle_changeset()
  end

  defp handle_changeset(%{valid?: true} = changeset), do: {:ok, changeset}
  defp handle_changeset(changeset), do: {:error, changeset}

  defp fetch_benefit_model(%{is_from_model: true} = context) do
    %{registration: %{org: org}, attrs: %{benefit_model_id: benefit_model_id}} = context

    case BenefitModels.fetch(org, benefit_model_id) do
      {:ok, %{disabled_at: nil} = model} -> {:ok, model}
      {:ok, _model} -> {:error, "benefit model is disabled"}
      {:error, :not_found} -> {:error, "benefit model not found"}
    end
  end

  defp fetch_benefit_model(%{is_from_model: false}), do: {:ok, nil}

  defp validate_existing_benefit(%{is_from_model: false} = context) do
    %{attrs: %{benefit_type: benefit_type}, registration: registration} = context

    registration
    |> Benefits.list_by_registration(types: [benefit_type], last_by: :start_date)
    |> do_validate_existing_benefit(context)
  end

  defp validate_existing_benefit(%{is_from_model: true} = context) do
    %{benefit_model: %{type: type}, registration: registration} = context

    registration
    |> Benefits.list_by_registration(types: [type], last_by: :start_date)
    |> do_validate_existing_benefit(context)
  end

  defp do_validate_existing_benefit([%{is_for_dependent: false, end_date: nil}], context) do
    if context.attrs.is_for_dependent,
      do: :ok,
      else: {:error, "existe um benefício do mesmo tipo em vigência"}
  end

  defp do_validate_existing_benefit(
         [%{is_for_dependent: false, end_date: last_end_date}],
         context
       ) do
    %{attrs: %{is_for_dependent: is_for_dependent, start_date: start_date}} = context

    if not is_for_dependent and Date.compare(start_date, last_end_date) == :lt do
      {:error,
       "a data de início deve ser posterior a data de término do último benefício do mesmo tipo"}
    else
      :ok
    end
  end

  defp do_validate_existing_benefit(_return, _context), do: :ok
end
