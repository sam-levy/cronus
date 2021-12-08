defmodule Sig.Map do
  @spec flat_put(map(), any(), any()) :: map()
  def flat_put(%{} = map, key, element) do
    existing_elements = Map.get(map, key, [])
    updated_elements = update_elements(element, existing_elements)

    Map.put(map, key, updated_elements)
  end

  defp update_elements(element, existing_elements) when is_list(element) do
    element ++ existing_elements
  end

  defp update_elements(element, existing_elements), do: [element | existing_elements]
end
