defmodule Sig.HR.BenefitModels do
  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.HR
  alias Sig.HR.BenefitModels.BenefitModel
  alias Sig.Organizations.Org
  alias Sig.Repo

  def create_change(%{} = attrs \\ %{}), do: BenefitModel.create_changeset(attrs)

  def update_change(%BenefitModel{} = benefit_model, %{} = attrs \\ %{}) do
    BenefitModel.update_changeset(benefit_model, attrs)
  end

  def update_amount_change(%BenefitModel{} = benefit_model, %{} = attrs \\ %{}) do
    BenefitModel.update_amount_changeset(benefit_model, attrs)
  end

  def disable_change(%BenefitModel{} = benefit_model, %{} = attrs \\ %{}) do
    BenefitModel.disable_changeset(benefit_model, attrs)
  end

  def list(%Org{} = org, opts \\ []) do
    BenefitModel
    |> where(org_id: ^org.id)
    |> filter_enabled(opts)
    |> Repo.all()
  end

  def get(%Org{} = org, id) when is_binary(id) do
    BenefitModel
    |> where(org_id: ^org.id)
    |> where(id: ^id)
    |> Repo.one()
  end

  def fetch(%Org{} = org, id) when is_binary(id) do
    case get(org, id) do
      %BenefitModel{} = model -> {:ok, model}
      nil -> {:error, :not_found}
    end
  end

  def create(%Org{} = org, %{} = attrs) do
    attrs
    |> Map.put(:org_id, org.id)
    |> BenefitModel.create_changeset()
    |> Repo.insert()
  end

  def update(%BenefitModel{} = benefit_model, %{} = attrs) do
    benefit_model
    |> BenefitModel.update_changeset(attrs)
    |> Repo.update()
  end

  def update_amount(%BenefitModel{} = benefit_model, %{} = attrs) do
    benefit_model
    |> BenefitModel.update_amount_changeset(attrs)
    |> Repo.update()
  end

  def disable(%BenefitModel{} = benefit_model, %{} = attrs) do
    benefit_model
    |> BenefitModel.disable_changeset(attrs)
    |> Repo.update()
  end

  def enable(%BenefitModel{} = benefit_model) do
    benefit_model
    |> BenefitModel.enable_changeset()
    |> Repo.update()
  end

  def delete(%BenefitModel{} = model) do
    case HR.count_benefits_by(model) do
      0 -> Repo.delete(model)
      _ -> {:error, "Existem benefícios associados ao modelo"}
    end
  end

  defp filter_enabled(queryable, opts) do
    case Keyword.get(opts, :filter, false) do
      :enabled -> where(queryable, [model], is_nil(model.disabled_at))
      false -> queryable
    end
  end

  def subscribe_to_benefit_models(schema), do: subscribe(topic(schema))

  def broadcast_new_benefit_model(%BenefitModel{} = sector) do
    broadcast(topic(sector), {:new_benefit_model, sector})
  end

  def broadcast_updated_benefit_model(%BenefitModel{} = sector) do
    broadcast(topic(sector), {:updated_benefit_model, sector})
  end

  def broadcast_deleted_benefit_model(%BenefitModel{} = sector) do
    broadcast(topic(sector), {:deleted_benefit_model, sector})
  end

  defp topic(%BenefitModel{} = sector), do: benefit_models_topic(sector.org_id)
  defp topic(%Org{} = org), do: benefit_models_topic(org.id)

  defp benefit_models_topic(org_id) do
    "org_id:" <> org_id <> ":benefit_models"
  end
end
