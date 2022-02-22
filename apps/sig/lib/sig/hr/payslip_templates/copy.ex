defmodule Sig.HR.PayslipTemplates.Copy do
  alias Ecto.Multi

  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem
  alias Sig.Repo

  def call(%PayslipTemplate{} = payslip_template, %{} = attrs) do
    Multi.new()
    |> Multi.insert(
      :payslip_template_copy,
      build_payslip_template_changeset(payslip_template, attrs)
    )
    |> Multi.insert_all(
      :payslip_template_items,
      PayslipTemplateItem,
      &build_payslip_template_items_attrs(payslip_template, &1.payslip_template_copy)
    )
    |> Repo.transaction()
    |> case do
      {:error, _operation, reason, _changes} -> {:error, reason}
      {:ok, %{payslip_template_copy: payslip_template_copy}} -> {:ok, payslip_template_copy}
    end
  end

  defp build_payslip_template_changeset(payslip_template, attrs) do
    attrs
    |> Map.put(:org_id, payslip_template.org_id)
    |> PayslipTemplate.create_changeset()
  end

  defp build_payslip_template_items_attrs(payslip_template, payslip_template_copy) do
    payslip_template
    |> PayslipTemplateItems.list()
    |> Enum.map(fn pti ->
      pti
      |> Map.from_struct()
      |> Map.put(:org_id, payslip_template_copy.org_id)
      |> Map.put(:payslip_template_id, payslip_template_copy.id)
      |> build_payslip_template_item_attrs()
      |> Map.get(:changes)
      |> Sig.Changeset.add_timestamps()
    end)
  end

  defp build_payslip_template_item_attrs(%{type: :payslip_item} = pti) do
    PayslipTemplateItem.create_payslip_template_item_changeset(pti)
  end

  defp build_payslip_template_item_attrs(%{type: :payslip_item_model} = pti) do
    PayslipTemplateItem.create_payslip_template_model_item_changeset(pti)
  end
end
