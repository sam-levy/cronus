defmodule Sig.Organizations.SectorsTest do
  use Sig.DataCase

  alias Sig.Organizations.Sectors
  alias Sig.Organizations.Sector

  @endpoint SigLive.Endpoint

  describe "change/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Sector{}} = Sectors.change(%Sector{}, %{})
    end
  end

  describe "change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Sector{}} = Sectors.change(%Sector{})
      assert %Ecto.Changeset{data: %Sector{}} = Sectors.change(%{})
    end
  end

  describe "list/1" do
    test "lists sectors by organizaition ordered by name" do
      org = insert(:org)

      insert(:org_sector, org: org, name: "Z")
      insert(:org_sector, org: org, name: "A")
      _to_ignore = insert(:org_sector)

      assert [
        %Sector{name: "A"},
        %Sector{name: "Z"}
      ] = Sectors.list(org)
    end

    test "when org has no sector" do
      org = insert(:org)

      assert Sectors.list(org) == []
    end
  end

  describe "get/2" do
    test "returns a sector" do
      org = insert(:org)

      %{id: id} = sector = insert(:org_sector, org: org)

      assert %Sector{id: ^id} = Sectors.get(org, sector.id)
    end

    test "when sector doesn't belong to the org" do
      org = insert(:org)
      sector = insert(:org_sector)

      assert Sectors.get(org, sector.id) == nil
    end

    test "when sector doesn't exist" do
      org = insert(:org)

      assert Sectors.get(org, UUID.generate()) == nil
    end
  end

  describe "create/2" do
    test "creates a sector" do
      org = insert(:org)

      attrs = %{name: "Kitchen"}

      assert {:ok, %Sector{id: id, name: "Kitchen"}} = Sectors.create(org, attrs)

      assert Repo.get_by(Sector, org_id: org.id, id: id, name: "Kitchen")
    end

    test "returns changeset errors" do
      org = insert(:org)

      assert {:error, changeset} = Sectors.create(org, %{})

      assert errors_on(changeset) == %{
        name: ["can't be blank"]
      }
    end
  end

  describe "update/2" do
    test "updates a sector" do
      org = insert(:org)
      sector = insert(:org_sector, org: org, name: "Kitchen")

      attrs = %{name: "Cleaning"}

      assert {:ok, %Sector{name: "Cleaning"}} = Sectors.update(sector, attrs)

      assert Repo.get_by(Sector, org_id: org.id, id: sector.id, name: "Cleaning")
    end

    test "returns changeset errors" do
      org = insert(:org)
      sector = insert(:org_sector, org: org, name: "Kitchen")

      attrs = %{name: nil}

      assert {:error, changeset} = Sectors.update(sector, attrs)

      assert errors_on(changeset) == %{
        name: ["can't be blank"]
      }

      assert Repo.get_by(Sector, org_id: org.id, id: sector.id, name: "Kitchen")
    end
  end

  describe "delete/1" do
    test "deletes a sector" do
      org = insert(:org)
      %{id: id} = sector = insert(:org_sector, org: org)

      assert {:ok, %Sector{id: ^id}} = Sectors.delete(sector)

      refute Repo.get_by(Sector, org_id: org.id, id: sector.id)
    end

    test "when sector is being used by a registration" do
      org = insert(:org)
      sector = insert(:org_sector, org: org)

      insert(:employee_registration, org: org, sector: sector)

      assert Sectors.delete(sector) == {:error, "Existem registros de funcionários associados"}

      assert Repo.get_by(Sector, org_id: org.id, id: sector.id)
    end
  end

  describe "subscribe_to_org_sectors/1" do
    test "subscribes to org sectors topic" do
      org = insert(:org)
      topic = "org_id:" <> org.id <> ":org_sectors"

      assert Sectors.subscribe_to_org_sectors(org) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:new_org_sector, :sector})

      assert_receive {:new_org_sector, :sector}
    end
  end

  describe "broadcast_new_org_sector/1" do
    test "broadcasts new sectors from an org" do
      org = insert(:org)
      sector = insert(:org_sector, org: org)

      topic = "org_id:" <> org.id <> ":org_sectors"

      @endpoint.subscribe(topic)

      assert Sectors.broadcast_new_org_sector(sector) == :ok

      assert_receive {:new_org_sector, received_sector}

      assert received_sector.id == sector.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_updated_org_sector/1" do
    test "broadcasts updated sectors from an org" do
      org = insert(:org)
      sector = insert(:org_sector, org: org)

      topic = "org_id:" <> org.id <> ":org_sectors"

      @endpoint.subscribe(topic)

      assert Sectors.broadcast_updated_org_sector(sector) == :ok

      assert_receive {:updated_org_sector, received_sector}

      assert received_sector.id == sector.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_deleted_org_sector/1" do
    test "broadcasts updated sectors from an org" do
      org = insert(:org)
      sector = insert(:org_sector, org: org)

      topic = "org_id:" <> org.id <> ":org_sectors"

      @endpoint.subscribe(topic)

      assert Sectors.broadcast_deleted_org_sector(sector) == :ok

      assert_receive {:deleted_org_sector, received_sector}

      assert received_sector.id == sector.id

      @endpoint.unsubscribe(topic)
    end
  end
end
