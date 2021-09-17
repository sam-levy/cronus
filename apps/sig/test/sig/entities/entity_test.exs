defmodule Sig.Entities.EntityTest do
  use Sig.DataCase

  alias Sig.Entities.Entity

  describe "entities table constraints" do
    test "organization foreign_key_constraint" do
      assert_raise Ecto.ConstraintError,
                   ~r/entities_organization_id_fkey \(foreign_key_constraint\)/,
                   fn ->
                     Repo.insert(%Entity{organization_id: UUID.generate()})
                   end
    end

    test "organization_id not_null_violation" do
      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"organization_id\" of relation \"entities\" violates not-null constraint/,
                   fn ->
                     Repo.insert(%Entity{})
                   end
    end

    test "inserts entity" do
      organization = insert(:organization)

      assert {:ok, entity} = Repo.insert(%Entity{organization_id: organization.id})

      assert entity.organization_id == organization.id
    end
  end
end
