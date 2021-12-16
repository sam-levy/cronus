defmodule Sig.HR.PayslipTemplates.PayslipTemplateItems do
  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem
  alias Sig.Repo

  def create_change(%{} = attrs \\ %{}) do
    PayslipTemplateItem.create_changeset(attrs)
  end

  def create(%PayslipTemplate{} = payslip_template, %{} = attrs) do
    attrs
    |> Map.put(:org_id, payslip_template.org_id)
    |> Map.put(:payslip_template_id, payslip_template.id)
    |> PayslipTemplateItem.create_changeset()
    |> Repo.insert()
  end

  def delete(%PayslipTemplateItem{} = payslip_template_item) do
    Repo.delete(payslip_template_item)
  end

  def list(%PayslipTemplate{} = payslip_template, _opts \\ []) do
    payslip_template
    |> query_by()
    |> preload_model_and_category()
    |> order_by([category: c], c.code)
    |> Repo.all()
  end

  def list_by(attrs) do
    init_query()
    |> where(^attrs)
    |> preload_model_and_category()
    |> order_by([category: c], c.code)
    |> Repo.all()
  end

  def get_by(attrs) do
    init_query()
    |> where(^attrs)
    |> preload_model_and_category()
    |> Repo.one()
  end

  defp query_by(%PayslipTemplate{} = payslip_template) do
    init_query()
    |> where(org_id: ^payslip_template.org_id)
    |> where(payslip_template_id: ^payslip_template.id)
  end

  defp init_query, do: from(template in PayslipTemplateItem, as: :payslip_template_item)

  defp preload_model_and_category(queryable) do
    queryable
    |> join(
      :left,
      [payslip_template_item: template_item],
      rim in assoc(template_item, :payslip_recurring_item_model),
      as: :payslip_recurring_item_model
    )
    |> join(:left, [payslip_recurring_item_model: rim], category in assoc(rim, :category),
      as: :category
    )
    |> preload([payslip_recurring_item_model: rim, category: category],
      payslip_recurring_item_model: {rim, category: category}
    )
  end

  def subscribe_to_payslip_template_items(schema), do: subscribe(topic(schema))

  def broadcast_new_payslip_template_item(%PayslipTemplateItem{} = payslip_template_item) do
    payslip_template_item =
      get_by(
        org_id: payslip_template_item.org_id,
        payslip_template_id: payslip_template_item.payslip_template_id,
        payslip_recurring_item_model_id: payslip_template_item.payslip_recurring_item_model_id
      )

    broadcast(topic(payslip_template_item), {:new_payslip_template_item, payslip_template_item})
  end

  def broadcast_deleted_payslip_template_item(%PayslipTemplateItem{} = payslip_template_item) do
    broadcast(
      topic(payslip_template_item),
      {:deleted_payslip_template_item, payslip_template_item}
    )
  end

  defp topic(%PayslipTemplateItem{} = payslip_template_item) do
    payslip_template_payslip_template_items_topic(payslip_template_item.payslip_template_id)
  end

  defp topic(%PayslipTemplate{} = payslip_template) do
    payslip_template_payslip_template_items_topic(payslip_template.id)
  end

  defp payslip_template_payslip_template_items_topic(payslip_template_id) do
    "payslip_template_id:" <> payslip_template_id <> ":payslip_template_items"
  end
end
