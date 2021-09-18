defmodule SigLive.Plugs.FetchOrgTest do
  use SigLive.ConnCase, async: true

  alias Sig.Organizations.Org
  alias SigLive.Plugs.FetchOrg

  describe "init/1" do
    test "does not modify the input" do
      assert FetchOrg.init(%{some: "map"}) == %{some: "map"}
    end
  end

  describe "call/2" do
    test "fetches org when org_id is in params", %{conn: conn} do
      org_id = insert(:org).id
      conn = %{conn | params: %{"org_id" => org_id}}

      conn = FetchOrg.call(conn, [])

      refute conn.halted

      assert conn.status == nil
      assert %Org{id: ^org_id} = conn.assigns.org
    end

    test "resumes when there is no org_id in params", %{conn: conn} do
      conn = FetchOrg.call(conn, [])

      refute conn.halted
      refute conn.assigns[:org]

      assert conn.status == nil
    end

    test "halts when org_id in params is invalid", %{conn: conn} do
      conn = %{conn | params: %{"org_id" => UUID.generate()}}

      conn = FetchOrg.call(conn, [])

      assert conn.halted
      assert conn.status == 404
    end
  end
end
