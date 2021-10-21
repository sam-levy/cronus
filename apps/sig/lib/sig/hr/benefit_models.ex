defmodule Sig.HR.BenefitModels do
  import Ecto.Query

  alias Sig.Organizations.Org
  alias Sig.HR.BenefitModels.BenefitModel
  alias Sig.Repo

  def list(%Org{} = org) do
    BenefitModel
    |> where(org_id: ^org.id)
    |> where([model], is_nil(model.disabled_at))
    |> Repo.all()
  end

  def get(%Org{} = org, id) when is_binary(id) do
    BenefitModel
    |> where(org_id: ^org.id)
    |> where(id: ^id)
    |> where([model], is_nil(model.disabled_at))
    |> Repo.one()
  end
end
