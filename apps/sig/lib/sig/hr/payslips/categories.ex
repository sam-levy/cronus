defmodule Sig.HR.Payslips.Categories do
  import Ecto.Query

  alias Sig.HR.Payslips.Categories.Category
  alias Sig.Repo

  def list(org_id) when is_binary(org_id) do
    Category
    |> where(org_id: ^org_id)
    |> Repo.all()
  end

  def get(org_id, id) when is_binary(org_id) and is_binary(id) do
    Category
    |> where(org_id: ^org_id)
    |> where(id: ^id)
    |> Repo.one()
  end

  def fetch(org_id, id) when is_binary(org_id) and is_binary(id) do
    case get(org_id, id) do
      %Category{} = category -> {:ok, category}
      nil -> {:error, :not_found}
    end
  end
end
