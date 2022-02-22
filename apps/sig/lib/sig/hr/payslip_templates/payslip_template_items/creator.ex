defmodule Sig.HR.PayslipTemplates.PayslipTemplateItems.Creator do
  alias Ecto.Multi

  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem
  alias Sig.Repo

  def create_payslip_template_item(%PayslipTemplate{} = payslip_template, %{} = attrs) do
    attrs
    |> assign_fks(payslip_template)
    |> PayslipTemplateItem.create_payslip_template_item_changeset()
    |> create_multi()
  end

  def create_payslip_template_model_item(%PayslipTemplate{} = payslip_template, %{} = attrs) do
    attrs
    |> assign_fks(payslip_template)
    |> PayslipTemplateItem.create_payslip_template_model_item_changeset()
    |> create_multi()
  end

  defp assign_fks(attrs, payslip_template) do
    attrs
    |> Map.put(:org_id, payslip_template.org_id)
    |> Map.put(:payslip_template_id, payslip_template.id)
  end

  defp create_multi(changeset) do
    Multi.new()
    |> Multi.insert(:item, changeset)
    |> Multi.run(:category_code, &validate_category_code/2)
    |> Repo.transaction()
    |> case do
      {:error, _operation, reason, _changes} -> {:error, reason}
      {:ok, %{item: item}} -> {:ok, item}
    end
  end

  defp validate_category_code(_repo, %{item: item}) do
    [org_id: item.org_id, payslip_template_id: item.payslip_template_id]
    |> PayslipTemplateItems.list_by()
    |> Enum.reduce_while(MapSet.new(), fn item, acc ->
      if MapSet.member?(acc, item.category_code) do
        {:halt, {:error, "Já exsite um item com o mesmo código neste modelo de holerite"}}
      else
        {:cont, MapSet.put(acc, item.category_code)}
      end
    end)
    |> case do
      %MapSet{} -> {:ok, nil}
      {:error, message} -> {:error, message}
    end
  end
end
