defmodule Sig.Reports.HR do
  import Ecto.Query

  alias Sig.Entities.Companies.Company
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org
  alias Sig.Repo

  def employee_count_per_assigned_company(%Org{} = org) do
    from(r in Registration, as: :registrations)
    |> where(org_id: ^org.id)
    |> where([registrations: r], is_nil(r.resignation_date))
    |> join_last_company_assignments()
    |> join(:left, [last_company_assignments: ca], c in Company,
      on: ca.assigned_company_id == c.entity_id,
      as: :last_assigned_companies
    )
    |> group_by([last_assigned_companies: lac], lac.trade_name)
    |> select([last_assigned_companies: lac], %{
      company_name: lac.trade_name,
      company_count: count(lac.trade_name)
    })
    |> Repo.all()
    |> Map.new(&{&1.company_name, %{count: &1.company_count}})
  end

  defp join_last_company_assignments(queryable) do
    join(
      queryable,
      :inner_lateral,
      [registrations: r],
      last_company_assignments in fragment(
        """
          SELECT *
          FROM employee_company_assignments
          WHERE org_id = ? AND
          registration_id = ?
          ORDER BY start_date DESC
          LIMIT 1
        """,
        r.org_id,
        r.id
      ),
      as: :last_company_assignments
    )
  end
end
