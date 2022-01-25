defmodule SigLive.Plugs.RedirectToOrgTest do
  use SigLive.ConnCase, async: true

  alias SigLive.Plugs.RedirectToOrg

  describe "init/1" do
    test "does not modify the input" do
      assert RedirectToOrg.init(%{some: "map"}) == %{some: "map"}
    end
  end

  describe "call/2" do
    test "redirects if the current_user has a role in the org", %{conn: conn} do
      org = insert(:org)
      user = insert(:user, org: org, org_roles: %{org.id => :regular})

      conn = %{conn | assigns: %{current_user: user}}

      conn = RedirectToOrg.call(conn, [])

      refute conn.halted
      assert conn.status == 302
    end

    test "halts if the current_user has no role at any org", %{conn: conn} do
      org = insert(:org)
      user = insert(:user, org: org, org_roles: %{})

      conn = %{conn | assigns: %{current_user: user}}

      conn = RedirectToOrg.call(conn, [])

      assert conn.halted
      assert conn.status == 403
    end

    test "halts when there is no current_user in the assigns", %{conn: conn} do
      conn = RedirectToOrg.call(conn, [])

      assert conn.halted
      assert conn.status == 403
    end
  end
end
