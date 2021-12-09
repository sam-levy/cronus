defmodule Sig.HR.PayslipTemplates do
  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.Organizations.Org
  alias Sig.Repo

  def create_change(%{} = attrs \\ %{}) do
    PayslipTemplate.create_changeset(attrs)
  end

  def update_change(%PayslipTemplate{} = payslip_template, %{} = attrs \\ %{}) do
    PayslipTemplate.update_changeset(payslip_template, attrs)
  end

  def create(%Org{} = org, %{} = attrs) do
    attrs
    |> Map.put(:org_id, org.id)
    |> PayslipTemplate.create_changeset()
    |> Repo.insert()
  end

  def update(%PayslipTemplate{} = payslip_template, %{} = attrs) do
    payslip_template
    |> PayslipTemplate.update_changeset(attrs)
    |> Repo.update()
  end

  def delete(%PayslipTemplate{} = payslip_template) do
    Repo.delete(payslip_template)
  end

  def get(%Org{} = org, id) when is_binary(id) do
    org
    |> query_by()
    |> where(id: ^id)
    |> Repo.one()
  end

  def list(%Org{} = org, _opts \\ []) do
    org
    |> query_by()
    |> order_by([payslip_template: t], t.name)
    |> Repo.all()
  end

  defp query_by(%Org{} = org), do: where(init_query(), org_id: ^org.id)

  defp init_query, do: from(template in PayslipTemplate, as: :payslip_template)

  def subscribe_to_payslip_templates(schema), do: subscribe(topic(schema))

  def broadcast_new_payslip_template(%PayslipTemplate{} = payslip_template) do
    broadcast(topic(payslip_template), {:new_payslip_template, payslip_template})
  end

  def broadcast_updated_payslip_template(%PayslipTemplate{} = payslip_template) do
    broadcast(topic(payslip_template), {:updated_payslip_template, payslip_template})
  end

  def broadcast_deleted_payslip_template(%PayslipTemplate{} = payslip_template) do
    broadcast(topic(payslip_template), {:deleted_payslip_template, payslip_template})
  end

  defp topic(%PayslipTemplate{} = payslip_template) do
    org_payslip_templates_topic(payslip_template.org_id)
  end

  defp topic(%Org{} = org) do
    org_payslip_templates_topic(org.id)
  end

  defp org_payslip_templates_topic(org_id) do
    "org_id:" <> org_id <> ":payslip_templates"
  end
end
