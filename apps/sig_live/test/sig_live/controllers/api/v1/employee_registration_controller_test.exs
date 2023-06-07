defmodule SigLive.Api.V1.EmployeeRegistrationControllerTest do
  use SigLive.ConnCase, async: true

  describe "GET /api/v1/orgs/:org_id/sector_name/:sector_name/employee_registrations [:index_by_sector]" do
    test "returns a list of employee registrations from an organization and sector", %{conn: conn} do
      org = insert(:org)
      individual_motoboy_1 = insert(:individual, org: org, name: "Motoboy One")
      individual_motoboy_2 = insert(:individual, org: org, name: "Motoboy Two")
      individual_cook = insert(:individual, org: org)
      company = insert(:company, org: org)

      registration_motoboy_1 =
        insert(:employee_registration,
          org: org,
          individual: individual_motoboy_1,
          registered_at: company
        )

      registration_motoboy_2 =
        insert(:employee_registration,
          org: org,
          individual: individual_motoboy_2,
          registered_at: company
        )

      registration_cook =
        insert(:employee_registration,
          org: org,
          individual: individual_cook,
          registered_at: company
        )

      sector_delivery = insert(:org_sector, org: org, name: "Delivery")
      sector_kitchen = insert(:org_sector, org: org, name: "Kitchen")

      insert(:employee_company_assignment,
        org: org,
        registration: registration_motoboy_1,
        assigned_company: company,
        sector: sector_delivery
      )

      insert(:employee_company_assignment,
        org: org,
        registration: registration_motoboy_2,
        assigned_company: company,
        sector: sector_delivery
      )

      insert(:employee_company_assignment,
        org: org,
        registration: registration_cook,
        assigned_company: company,
        sector: sector_kitchen
      )

      response =
        conn
        |> get(Routes.employee_registration_path(conn, :index_by_sector, org.id, "Delivery"))
        |> json_response(200)

      assert %{
               "data" => [
                 %{
                   "org_id" => _,
                   "resignation_date" => _,
                   "company_entity_id" => _,
                   "individual" => %{
                     "entity_id" => _,
                     "name" => _
                   }
                 },
                 %{
                   "org_id" => _,
                   "resignation_date" => _,
                   "company_entity_id" => _,
                   "individual" => %{
                     "entity_id" => _,
                     "name" => _
                   }
                 }
               ]
             } = response
    end

    test "scope by org", %{conn: conn} do
      org_1 = insert(:org)
      org_2 = insert(:org)
      individual_motoboy_1 = insert(:individual, org: org_1, name: "Motoboy One")
      individual_motoboy_2 = insert(:individual, org: org_2, name: "Motoboy Two")
      company_1 = insert(:company, org: org_1)
      company_2 = insert(:company, org: org_2)

      registration_motoboy_1 =
        insert(:employee_registration,
          org: org_1,
          individual: individual_motoboy_1,
          registered_at: company_1
        )

      registration_motoboy_2 =
        insert(:employee_registration,
          org: org_2,
          individual: individual_motoboy_2,
          registered_at: company_2
        )

      sector_org_1 = insert(:org_sector, org: org_1, name: "Delivery")
      sector_org_2 = insert(:org_sector, org: org_2, name: "Delivery")

      insert(:employee_company_assignment,
        org: org_1,
        registration: registration_motoboy_1,
        assigned_company: company_1,
        sector: sector_org_1
      )

      insert(:employee_company_assignment,
        org: org_2,
        registration: registration_motoboy_2,
        assigned_company: company_2,
        sector: sector_org_2
      )

      response =
        conn
        |> get(Routes.employee_registration_path(conn, :index_by_sector, org_1.id, "Delivery"))
        |> json_response(200)

      assert %{
               "data" => [
                 %{
                   "org_id" => _,
                   "resignation_date" => _,
                   "company_entity_id" => _,
                   "individual" => %{
                     "entity_id" => _,
                     "name" => _
                   }
                 }
               ]
             } = response
    end

    test "when org does not exist", %{conn: conn} do
      org_id = UUID.generate()

      response =
        conn
        |> get(Routes.employee_registration_path(conn, :index_by_sector, org_id, "Delivery"))
        |> json_response(404)

      assert response == %{"error" => "Not found"}
    end

    test "when uuid is invalid", %{conn: conn} do
      response =
        conn
        |> get(Routes.company_path(conn, :index, "invalid UUID", sector_name: "Delivery"))
        |> json_response(400)

      assert response == %{
               "error" => %{
                 "org_id" => ["is in valid"]
               }
             }
    end
  end
end
