defmodule SigLive.Api.V1.CompanyController do
  use SigLive, :controller

  alias Sig.Entities
  alias Sig.Organizations

  @index %{
    org_id: [type: Ecto.UUID, required: true]
  }

  def index(conn, params) do
    with {:ok, %{org_id: org_id}} <- Tarams.cast(params, @index),
         {:ok, org} <- Organizations.fetch_org(org_id) do
      conn
      |> put_status(:ok)
      |> render(companies: Entities.list_companies(org))
    end
  end
end
