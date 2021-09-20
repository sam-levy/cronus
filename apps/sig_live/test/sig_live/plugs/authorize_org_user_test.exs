defmodule SigLive.Plugs.AuthorizeOrgUserTest do
  use SigLive.ConnCase, async: true

  alias SigLive.Plugs.AuthorizeOrgUser

  describe "init/1" do
    test "does not modify the input" do
      assert AuthorizeOrgUser.init(%{some: "map"}) == %{some: "map"}
    end
  end

  describe "call/2" do
    test "resumes if the current_user has a role in the org", %{conn: conn} do
      org = insert(:org)
      user = insert(:user, org: org, org_roles: %{org.id => :regular})

      conn = %{conn | assigns: %{current_user: user, org: org}}

      conn = AuthorizeOrgUser.call(conn, [])

      refute conn.halted
      assert conn.status == nil
    end

    test "halts if the current_user has no role in the org", %{conn: conn} do
      org = insert(:org)
      user = insert(:user, org: org, org_roles: %{org.id => :admin})

      another_org = insert(:org)

      conn = %{conn | assigns: %{current_user: user, org: another_org}}

      conn = AuthorizeOrgUser.call(conn, [])

      assert conn.halted
      assert conn.status == 403
    end

    test "halts when there is no current_user in the assigns", %{conn: conn} do
      org = insert(:org)
      conn = %{conn | assigns: %{org: org}}

      conn = AuthorizeOrgUser.call(conn, [])

      assert conn.halted
      assert conn.status == 403
    end

    test "halts when there is no org in the assigns", %{conn: conn} do
      org = insert(:org)
      user = insert(:user, org: org, org_roles: %{org.id => :regular})

      conn = %{conn | assigns: %{current_user: user}}

      conn = AuthorizeOrgUser.call(conn, [])

      assert conn.halted
      assert conn.status == 403
    end
  end
end
