defmodule Sig.HR.PayslipTemplates.PayslipTemplateItems do
  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.Creator
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem
  alias Sig.Repo

  defdelegate create_payslip_item(payslip_template, attrs), to: Creator
  defdelegate create_payslip_model_item(payslip_template, attrs), to: Creator

  def create_payslip_item_change(%{} = attrs \\ %{}) do
    PayslipTemplateItem.create_payslip_item_changeset(attrs)
  end

  def create_payslip_model_item_change(%{} = attrs \\ %{}) do
    PayslipTemplateItem.create_payslip_model_item_changeset(attrs)
  end

  def delete(%PayslipTemplateItem{} = payslip_template_item) do
    Repo.delete(payslip_template_item)
  end

  def list(%PayslipTemplate{} = payslip_template, _opts \\ []) do
    payslip_template
    |> query_by()
    |> preloads()
    |> Repo.all()
    |> fill_category_code()
    |> order_by_category_code()
  end

  def list_by(attrs) do
    init_query()
    |> where(^attrs)
    |> preloads()
    |> Repo.all()
    |> fill_category_code()
  end

  def get_by(attrs) do
    init_query()
    |> where(^attrs)
    |> preloads()
    |> Repo.one()
    |> fill_category_code()
  end

  defp query_by(%PayslipTemplate{} = payslip_template) do
    init_query()
    |> where(org_id: ^payslip_template.org_id)
    |> where(payslip_template_id: ^payslip_template.id)
  end

  defp init_query, do: from(template in PayslipTemplateItem, as: :payslip_template_item)

  defp preloads(queryable) do
    queryable
    |> join(
      :left,
      [payslip_template_item: template_item],
      rim in assoc(template_item, :payslip_recurring_item_model),
      as: :payslip_recurring_item_model
    )
    |> join(
      :left,
      [payslip_template_item: template_item],
      rim in assoc(template_item, :payslip_category),
      as: :payslip_category
    )
    |> join(:left, [payslip_recurring_item_model: rim], category in assoc(rim, :category),
      as: :payslip_recurring_item_model_category
    )
    |> preload(
      [
        payslip_recurring_item_model: rim,
        payslip_category: payslip_category,
        payslip_recurring_item_model_category: rim_category
      ],
      payslip_recurring_item_model: {rim, category: rim_category},
      payslip_category: payslip_category
    )
  end

  defp fill_category_code([]), do: []

  defp fill_category_code([_ | _] = items), do: Enum.map(items, &fill_category_code/1)

  defp fill_category_code(%PayslipTemplateItem{type: :payslip_item} = item) do
    %{item | category_code: item.payslip_category.code}
  end

  defp fill_category_code(%PayslipTemplateItem{type: :payslip_item_model} = item) do
    %{item | category_code: item.payslip_recurring_item_model.category.code}
  end

  defp order_by_category_code([_ | _] = items), do: Enum.sort_by(items, & &1.category_code)
  defp order_by_category_code(items), do: items

  def subscribe_to_payslip_template_items(schema), do: subscribe(topic(schema))

  def broadcast_new_payslip_template_item(%PayslipTemplateItem{} = payslip_template_item) do
    payslip_template_item =
      get_by(org_id: payslip_template_item.org_id, id: payslip_template_item.id)

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
