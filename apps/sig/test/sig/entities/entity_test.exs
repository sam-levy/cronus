defmodule Sig.Entities.EntityTest do
  use Sig.DataCase

  alias Sig.Entities.Entity

  describe "entities table constraints" do
    test "org_id not_null_violation" do
      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"entities\" violates not-null constraint/,
                   fn ->
                     Repo.insert(%Entity{})
                   end
    end

    test "org_id foreign_key_constraint" do
      assert_raise Ecto.ConstraintError,
                   ~r/entities_org_id_fkey \(foreign_key_constraint\)/,
                   fn ->
                     Repo.insert(%Entity{org_id: UUID.generate()})
                   end
    end

    test "valid attrs" do
      org = insert(:org)

      assert {:ok, entity} = Repo.insert(%Entity{org_id: org.id})

      assert Repo.get_by(Entity,
        id: entity.id,
        org_id: org.id
      )
    end
  end
end
