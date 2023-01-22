defmodule Sig.UUIDTest do
  use Sig.DataCase, async: true

  import Sig.UUID

  describe "is_uuid?/1" do
    test "with a valid UUID" do
      uuid = Ecto.UUID.generate()

      assert is_uuid?(uuid)
    end

    test "with an invalid UUID" do
      refute is_uuid?("11a26fb8-d15f-454c-")
    end

    test "with a non string value" do
      refute is_uuid?(:not_a_string)
    end
  end
end
