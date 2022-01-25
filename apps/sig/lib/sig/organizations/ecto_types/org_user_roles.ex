defmodule Sig.Organizations.EctoTypes.OrgUserRoles do
  @moduledoc """
  An `Ecto.Type` for OrgUserRoles.
  """
  use Ecto.Type

  alias Ecto.UUID
  alias Sig.Organizations.UserTypes

  @type org_user_roles :: %{UUID.t() => UserTypes.t()}

  def type, do: :org_user_roles

  def cast(values) when is_map(values) do
    values
    |> Enum.reduce_while(%{}, fn {org_id, user_role}, acc ->
      with {:ok, org_id} <- UUID.cast(org_id),
           {:ok, user_role} <- UserTypes.cast(user_role) do
        {:cont, Map.put(acc, org_id, user_role)}
      else
        :error -> {:halt, :error}
      end
    end)
    |> case do
      :error -> :error
      casted_values -> {:ok, casted_values}
    end
  end

  def cast(_invalid), do: :error

  def load(value), do: cast(value)

  def dump(value) when is_map(value), do: cast(value)
  def dump(_invalid), do: :error
end
