defmodule Sig.Reports.HRTest do
  use Sig.DataCase, async: true

  alias Sig.Reports.HR

  describe "employee_count_per_assigned_company/1" do
    test "returns the employee count per designated company" do
      org = insert(:org)
      date = ~D[2020-01-01]

      # Company 1

      company_1 = insert(:company, org: org, trade_name: "Company 1")

      company_1_reg_1 =
        insert(:employee_registration, admission_date: date, org: org, registered_at: company_1)

      insert(:employee_company_assignment,
        org: org,
        registration: company_1_reg_1,
        assigned_company: company_1,
        start_date: date
      )

      # Company 2

      company_2 = insert(:company, org: org, trade_name: "Company 2")

      company_2_reg_1 =
        insert(:employee_registration, org: org, admission_date: date, registered_at: company_2)

      # Ignores older comany assignment
      insert(:employee_company_assignment,
        org: org,
        registration: company_2_reg_1,
        assigned_company: build(:company, org: org, trade_name: "To ignore 1"),
        start_date: date
      )

      insert(:employee_company_assignment,
        org: org,
        registration: company_2_reg_1,
        assigned_company: company_2,
        start_date: Date.add(date, 180)
      )

      # Company 3 resigned registration to ignore

      company_3 = insert(:company, org: org, trade_name: "Company 3")

      company_3_reg_1 =
        insert(:employee_registration,
          org: org,
          admission_date: date,
          registered_at: company_3,
          resignation_date: Date.add(date, 180),
          resignation_type: :resigned
        )

      insert(:employee_company_assignment,
        org: org,
        registration: company_3_reg_1,
        assigned_company: company_3,
        start_date: date
      )

      # Company 4 assigned to company 1

      company_4 = insert(:company, org: org, trade_name: "Company 4")

      company_4_reg_1 =
        insert(:employee_registration, org: org, admission_date: date, registered_at: company_4)

      insert(:employee_company_assignment,
        org: org,
        registration: company_4_reg_1,
        assigned_company: company_1,
        start_date: date
      )

      assert HR.employee_count_per_assigned_company(org) == %{
               "Company 1" => %{count: 2},
               "Company 2" => %{count: 1}
             }
    end
  end
end
