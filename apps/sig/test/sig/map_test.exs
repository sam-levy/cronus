defmodule Sig.MapTest do
  use Sig.DataCase, async: true

  describe "flat_put/3" do
    test "creates a new key" do
      assert Sig.Map.flat_put(%{}, :key, :element) == %{key: [:element]}

      assert Sig.Map.flat_put(%{existing: [:element]}, :new, :element) == %{
               existing: [:element],
               new: [:element]
             }
    end

    test "adds element to the existing list" do
      map = %{key: ["element_1"]}

      assert Sig.Map.flat_put(map, :key, "element_2") == %{key: ["element_2", "element_1"]}
    end

    test "merges element to the existing list when element is a list" do
      map = %{key: ["element_1"]}

      assert Sig.Map.flat_put(map, :key, ["element_2"]) == %{key: ["element_2", "element_1"]}
    end
  end
end
