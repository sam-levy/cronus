defmodule Sig.Organizations.EctoTypes.OrgUserRolesTest do
  use Sig.DataCase

  alias Sig.Organizations.EctoTypes.OrgUserRoles

  test "type/0" do
    assert OrgUserRoles.type() == :org_user_roles
  end

  describe "cast/1" do
    test "when valid map" do
      org_id_1 = UUID.generate()
      org_id_2 = UUID.generate()

      value = %{
        org_id_1 => "admin",
        org_id_2 => :regular
      }

      assert OrgUserRoles.cast(value) ==
               {:ok,
                %{
                  org_id_1 => :admin,
                  org_id_2 => :regular
                }}
    end

    test "when roles are invalid" do
      value = %{
        UUID.generate() => "super",
        UUID.generate() => "regular"
      }

      assert OrgUserRoles.cast(value) == :error
    end

    test "when keys are invalid" do
      value = %{
        "invalid_key" => "admin",
        UUID.generate() => "regular"
      }

      assert OrgUserRoles.cast(value) == :error
    end

    test "when invalid value" do
      assert OrgUserRoles.cast("not_a_map") == :error
    end
  end

  describe "load/1" do
    test "when valid" do
      org_id_1 = UUID.generate()
      org_id_2 = UUID.generate()

      value = %{
        org_id_1 => "admin",
        org_id_2 => :regular
      }

      assert OrgUserRoles.load(value) ==
               {:ok,
                %{
                  org_id_1 => :admin,
                  org_id_2 => :regular
                }}
    end

    test "when invalid" do
      value = %{
        "invalid_key" => "admin",
        UUID.generate() => "regular"
      }

      assert OrgUserRoles.load(value) == :error
    end
  end

  describe "dump/1" do
    test "when valid" do
      org_id_1 = UUID.generate()
      org_id_2 = UUID.generate()

      value = %{
        org_id_1 => "admin",
        org_id_2 => :regular
      }

      assert OrgUserRoles.dump(value) ==
               {:ok,
                %{
                  org_id_1 => :admin,
                  org_id_2 => :regular
                }}
    end

    test "when invalid" do
      value = %{
        "invalid_key" => "admin",
        UUID.generate() => "regular"
      }

      assert OrgUserRoles.dump(value) == :error
    end

    test "when invalid value" do
      assert OrgUserRoles.dump("not_a_map") == :error
    end
  end
end
