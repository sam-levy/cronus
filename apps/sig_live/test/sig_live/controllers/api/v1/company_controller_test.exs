defmodule SigLive.Api.V1.CompanyControllerTest do
  use SigLive.ConnCase, async: true

  describe "GET /api/v1/orgs/:org_id/companies [:index]" do
    test "returns a list of companies from an organization", %{conn: conn} do
      org = insert(:org)
      insert_list(2, :company, org: org)
      insert(:company)

      response =
        conn
        |> get(Routes.company_path(conn, :index, org.id))
        |> json_response(200)

      assert %{
               "data" => [
                 %{
                   "entity_id" => _,
                   "org_id" => _,
                   "trade_name" => _,
                   "is_virtual" => _
                 },
                 %{
                   "entity_id" => _,
                   "org_id" => _,
                   "trade_name" => _,
                   "is_virtual" => _
                 }
               ]
             } = response
    end

    test "when org does not exist", %{conn: conn} do
      org_id = UUID.generate()

      response =
        conn
        |> get(Routes.company_path(conn, :index, org_id))
        |> json_response(404)

      assert response == %{"error" => "Not found"}
    end

    test "when uuid is invalid", %{conn: conn} do
      response =
        conn
        |> get(Routes.company_path(conn, :index, "invalid UUID"))
        |> json_response(400)

      assert response == %{
               "error" => %{
                 "org_id" => ["is in valid"]
               }
             }
    end
  end
end
