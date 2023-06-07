defmodule SigLive.Api.V1.EmployeeRegistrationController do
  use SigLive, :controller

  alias Sig.HR
  alias Sig.Organizations

  @index_by_sector %{
    org_id: [type: Ecto.UUID, required: true],
    sector_name: [type: :string, required: true]
  }

  def index_by_sector(conn, params) do
    with {:ok, params} <- Tarams.cast(params, @index_by_sector),
         {:ok, sector} <-
           Organizations.fetch_org_sector_by(org_id: params.org_id, name: params.sector_name) do
      registrations =
        HR.list_registrations_by(sector, preload: [:registered_at, :individual, :last_sector])

      conn
      |> put_status(:ok)
      |> render(employee_registrations: registrations)
    end
  end
end
