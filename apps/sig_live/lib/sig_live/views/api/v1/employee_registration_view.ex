defmodule SigLive.Api.V1.EmployeeRegistrationView do
  use SigLive, :view

  def render("index_by_sector.json", %{employee_registrations: reigstrations}) do
    %{data: render_many(reigstrations, __MODULE__, "employee_registration.json")}
  end

  def render("employee_registration.json", %{employee_registration: registration}) do
    %{
      org_id: registration.org_id,
      company_entity_id: registration.registered_at_id,
      resignation_date: registration.resignation_date,
      individual: %{
        entity_id: registration.individual.entity_id,
        name: registration.individual.name
      },
      sector: %{
        name: registration.last_sector.name
      }
    }
  end
end
