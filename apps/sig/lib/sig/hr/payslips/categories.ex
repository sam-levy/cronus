defmodule Sig.HR.Payslips.Categories do
  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.HR
  alias Sig.HR.Payslips.Categories.Category
  alias Sig.Organizations.Org
  alias Sig.Repo

  def create_change(%{} = attrs \\ %{}) do
    Category.create_changeset(attrs)
  end

  def update_change(%Category{} = category, %{} = attrs \\ %{}) do
    Category.update_changeset(category, attrs)
  end

  def create(%Org{} = org, %{} = attrs) do
    attrs
    |> Map.put(:org_id, org.id)
    |> Category.create_changeset()
    |> Repo.insert()
  end

  def update(%Category{} = category, %{} = attrs) do
    category
    |> Category.update_changeset(attrs)
    |> Repo.update()
  end

  def delete(%Category{} = category) do
    with {:rim, 0} <- {:rim, HR.count_payslip_recurring_item_models_by(category)},
         {:rpi, 0} <- {:rpi, HR.count_recurring_payslip_items_by(category)} do
      Repo.delete(category)
    else
      {:rim, _} -> {:error, "Existem modelos de items de holerite associados"}
      {:rpi, _} -> {:error, "Existem items de holerite modelo associados"}
    end
  end

  def list(%Org{} = org), do: list(org.id)

  def list(org_id) when is_binary(org_id) do
    Category
    |> where(org_id: ^org_id)
    |> order_by(:code)
    |> Repo.all()
  end

  def get(%Org{} = org, id) when is_binary(id), do: get(org.id, id)

  def get(org_id, id) when is_binary(org_id) and is_binary(id) do
    Category
    |> where(org_id: ^org_id)
    |> where(id: ^id)
    |> Repo.one()
  end

  def fetch(org_id, id) when is_binary(org_id) and is_binary(id) do
    case get(org_id, id) do
      %Category{} = category -> {:ok, category}
      nil -> {:error, :not_found}
    end
  end

  def subscribe_to_payslip_categories(schema), do: subscribe(topic(schema))

  def broadcast_new_payslip_category(%Category{} = category) do
    broadcast(topic(category), {:new_payslip_category, category})
  end

  def broadcast_updated_payslip_category(%Category{} = category) do
    broadcast(topic(category), {:updated_payslip_category, category})
  end

  def broadcast_deleted_payslip_category(%Category{} = category) do
    broadcast(topic(category), {:deleted_payslip_category, category})
  end

  defp topic(%Category{} = category), do: org_categories_topic(category.org_id)
  defp topic(%Org{} = org), do: org_categories_topic(org.id)

  defp org_categories_topic(org_id) do
    "org_id:" <> org_id <> ":payslip_categories"
  end
end
