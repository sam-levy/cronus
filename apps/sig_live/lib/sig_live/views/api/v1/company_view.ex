defmodule SigLive.Api.V1.CompanyView do
  use SigLive, :view

  def render("index.json", %{companies: companies}) do
    %{data: render_many(companies, __MODULE__, "company.json")}
  end

  def render("company.json", %{company: company}) do
    %{
      org_id: company.org_id,
      entity_id: company.entity_id,
      trade_name: company.trade_name
    }
  end
end
