defmodule Sig.HR.Payslips.Categories do
  import Ecto.Query

  alias Sig.HR.Payslips.Categories.Category
  alias Sig.Organizations.Org
  alias Sig.Repo

  def list(%Org{} = org) do
    Category
    |> where(org_id: ^org.id)
    |> Repo.all()
  end

  def get(%Org{} = org, id) when is_binary(id) do
    Category
    |> where(org_id: ^org.id)
    |> where(id: ^id)
    |> Repo.one()
  end
end
