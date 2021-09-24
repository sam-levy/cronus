defmodule Sig.Entities.EntityTest do
  use Sig.DataCase

  alias Sig.Entities.Entity

  describe "entities table constraints" do
    test "org_id not_null_violation" do
      entity = %Entity{
        type: :physical
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"entities\" violates not-null constraint/,
                   fn -> Repo.insert(entity) end
    end

    test "org_id foreign_key_constraint" do
      entity = %Entity{
        org_id: UUID.generate(),
        type: :physical
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(entity) end
    end

    test "type not_null_violation" do
      org = insert(:org)

      entity = %Entity{
        org_id: org.id,
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"type\" of relation \"entities\" violates not-null constraint/,
                   fn -> Repo.insert(entity) end
    end

    test "invalid type" do
      org = insert(:org)

      entity = %Entity{
        org_id: org.id,
        type: :invalid
      }

      assert_raise Ecto.ChangeError,
                   ~r/\Value `:invalid` is not a valid enum for `Sig.Entities.Entity.EntityType`/,
                   fn -> Repo.insert(entity) end
    end

    test "valid attrs" do
      org = insert(:org)

      entity = %Entity{
        org_id: org.id,
        type: :legal
      }

      assert {:ok, entity} = Repo.insert(entity)

      assert Repo.get_by(Entity,
        id: entity.id,
        org_id: org.id,
        type: :legal
      )
    end
  end
end
