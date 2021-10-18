defmodule Sig.HR.BenefitModels do
  import Ecto.Query

  alias Sig.Organizations.Org
  alias Sig.HR.BenefitModels.BenefitModel
  alias Sig.Repo

  def get(%Org{} = org, id) when is_binary(id) do
    BenefitModel
    |> where(org_id: ^org.id)
    |> where(id: ^id)
    |> Repo.one()
  end
end
