defmodule Sig.HR.Payslips.RecurringItemModels do
  use Sig.Preloader, payslip_recurring_item_model: [:category]

  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.HR
  alias Sig.HR.Payslips.Categories.Category
  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel
  alias Sig.Organizations.Org
  alias Sig.Repo

  def create_change(%{} = attrs \\ %{}) do
    RecurringItemModel.create_changeset(attrs)
  end

  def update_change(%RecurringItemModel{} = rim, %{} = attrs \\ %{}) do
    RecurringItemModel.update_changeset(rim, attrs)
  end

  def create(%Org{} = org, %{} = attrs) do
    attrs
    |> Map.put(:org_id, org.id)
    |> RecurringItemModel.create_changeset()
    |> Repo.insert()
  end

  def update(%RecurringItemModel{} = rim, %{} = attrs) do
    rim
    |> RecurringItemModel.update_changeset(attrs)
    |> Repo.update()
  end

  def list(%Org{} = org, _opts \\ []) do
    org
    |> query_by()
    |> shallow_preload(:category)
    |> order_by([category: c], c.code)
    |> Repo.all()
  end

  def list_by(schema, _opts \\ []) do
    schema
    |> query_by()
    |> Repo.all()
  end

  def count_by(schema) do
    schema
    |> query_by()
    |> Repo.aggregate(:count)
  end

  def get(%Org{} = org, id, _opts \\ []) when is_binary(id) do
    org
    |> query_by()
    |> where([payslip_recurring_item_model: rim], rim.id == ^id)
    |> shallow_preload(:category)
    |> Repo.one()
  end

  def get_by(attrs, _opts \\ []) do
    init_query()
    |> where(^attrs)
    |> shallow_preload(:category)
    |> Repo.one()
  end

  def delete(%RecurringItemModel{} = rim) do
    case HR.count_recurring_payslip_items_by(rim) do
      0 -> Repo.delete(rim)
      _ -> {:error, "Existem holerites modelo usando este modelo de item"}
    end
  end

  defp query_by(%Org{} = org) do
    init_query()
    |> where(org_id: ^org.id)
  end

  defp query_by(%Category{} = category) do
    init_query()
    |> where(org_id: ^category.org_id)
    |> where(category_id: ^category.id)
  end

  defp init_query, do: from(rim in RecurringItemModel, as: :payslip_recurring_item_model)

  def subscribe_to_payslip_recurring_item_models(schema), do: subscribe(topic(schema))

  def broadcast_new_payslip_recurring_item_model(%RecurringItemModel{} = rim, opts \\ []) do
    broadcast(topic(rim), {:new_payslip_recurring_item_model, handle_opts(rim, opts)})
  end

  def broadcast_updated_payslip_recurring_item_model(%RecurringItemModel{} = rim, opts \\ []) do
    broadcast(topic(rim), {:updated_payslip_recurring_item_model, handle_opts(rim, opts)})
  end

  def broadcast_deleted_payslip_recurring_item_model(%RecurringItemModel{} = rim) do
    broadcast(topic(rim), {:deleted_payslip_recurring_item_model, rim})
  end

  defp topic(%RecurringItemModel{} = rim) do
    org_payslip_recurring_item_models_topic(rim.org_id)
  end

  defp topic(%Org{} = org) do
    org_payslip_recurring_item_models_topic(org.id)
  end

  defp org_payslip_recurring_item_models_topic(org_id) do
    "org_id:" <> org_id <> ":payslip_recurring_item_models"
  end

  defp handle_opts(rim, opts) do
    if Keyword.get(opts, :refetch, false) do
      get_by([org_id: rim.org_id, id: rim.id], opts)
    else
      rim
    end
  end
end
