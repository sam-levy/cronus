defmodule Sig.HR.PayslipTemplates.Copy do
  alias Ecto.Multi

  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem
  alias Sig.Repo

  def call(%PayslipTemplate{} = payslip_template, %{} = attrs) do
    Multi.new()
    |> Multi.insert(
      :new_payslip_template,
      build_payslip_template_changeset(payslip_template, attrs)
    )
    |> Multi.insert_all(
      :payslip_template_items,
      PayslipTemplateItem,
      &build_payslip_template_items_attrs(payslip_template, &1.new_payslip_template)
    )
    |> Repo.transaction()
    |> case do
      {:error, _operation, reason, _changes} -> {:error, reason}
      {:ok, %{new_payslip_template: new_payslip_template}} -> {:ok, new_payslip_template}
    end
  end

  defp build_payslip_template_changeset(payslip_template, attrs) do
    attrs
    |> Map.put(:org_id, payslip_template.org_id)
    |> PayslipTemplate.create_changeset()
  end

  defp build_payslip_template_items_attrs(payslip_template, new_payslip_template) do
    payslip_template
    |> PayslipTemplateItems.list()
    |> Enum.map(fn pti ->
      pti
      |> Map.from_struct()
      |> Map.put(:org_id, new_payslip_template.org_id)
      |> Map.put(:payslip_template_id, new_payslip_template.id)
      |> build_payslip_template_item_changeset()
      |> Map.get(:changes)
      |> Sig.Changeset.add_timestamps()
    end)
  end

  defp build_payslip_template_item_changeset(%{type: :payslip_item} = pti) do
    PayslipTemplateItem.create_payslip_template_item_changeset(pti)
  end

  defp build_payslip_template_item_changeset(%{type: :payslip_item_model} = pti) do
    PayslipTemplateItem.create_payslip_template_model_item_changeset(pti)
  end
end
