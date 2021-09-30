defmodule Sig.Organizations.PositionTest do
  use Sig.DataCase

  alias Sig.Organizations.Position

  describe "org_sectors table constraints" do
    test "org_id not_null_violation" do
      position = %Position{
        name: "store manager"
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"org_positions\" violates not-null constraint/,
                   fn -> Repo.insert(position) end
    end

    test "org_id foreign_key_constraint" do
      position = %Position{
        org_id: UUID.generate(),
        name: "store manager"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/org_positions_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(position) end
    end

    test "name not_null_violation" do
      org = insert(:org)

      position = %Position{
        org_id: org.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"name\" of relation \"org_positions\" violates not-null constraint/,
                   fn -> Repo.insert(position) end
    end

    test "org_positions_pkey citext unique_constraint" do
      org = insert(:org)
      insert(:position, org: org, name: "store manager")

      position = %Position{
        org_id: org.id,
        name: "STORE MANAGER"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/org_positions_pkey \(unique_constraint\)/,
                   fn -> Repo.insert(position) end
    end

    test "valid attrs" do
      org = insert(:org)

      position = %Position{
        org_id: org.id,
        name: "delivery person"
      }

      assert {:ok, _position} = Repo.insert(position)

      assert Repo.get_by(Position,
               org_id: org.id,
               name: "delivery person"
             )
    end
  end
end
