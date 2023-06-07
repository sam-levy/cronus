defmodule Sig.Organizations.SectorsTest do
  use Sig.DataCase, async: true

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

  describe "fetch_by/1" do
    test "fetches a sector" do
      org = insert(:org)
      insert(:org_sector, org: org, name: "Entrega")
      insert(:org_sector, org: org, name: "Cozinha")

      assert {:ok, %Sector{name: "Entrega"}} = Sectors.fetch_by(org_id: org.id, name: "Entrega")
    end

    test "when sector doesn't belong to the org" do
      org = insert(:org)
      insert(:org_sector, name: "Entrega")

      assert Sectors.fetch_by(org_id: org.id, name: "Entrega") == {:error, :not_found}
    end

    test "when sector doesn't exist" do
      org = insert(:org)

      assert Sectors.fetch_by(org_id: org.id, name: "Entrega") == {:error, :not_found}
    end

    test "when org doesn't exist" do
      insert(:org_sector, name: "Entrega")

      assert Sectors.fetch_by(org_id: UUID.generate(), name: "Entrega") == {:error, :not_found}
    end

    test "when org_id is not in the filters" do
      insert(:org_sector, name: "Entrega")

      assert {:error,
              %{
                message: "required :org_id option not found, received options: [:name]"
              }} = Sectors.fetch_by(name: "Entrega")
    end

    test "invalid filter" do
      org = insert(:org)
      insert(:org_sector, org: org, name: "Entrega")

      assert {:error,
              %{
                message: "unknown options [:invalid_option], valid options are: [:org_id, :name]"
              }} = Sectors.fetch_by(org_id: org.id, name: "Entrega", invalid_option: "invalid")
    end

    test "raises on more then one result" do
      org = insert(:org)
      insert(:org_sector, org: org, name: "Entrega")
      insert(:org_sector, org: org, name: "Cozinha")

      assert_raise Ecto.MultipleResultsError, fn ->
        Sectors.fetch_by(org_id: org.id)
      end
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
      registration = insert(:employee_registration, org: org)

      insert(:employee_company_assignment,
        org: org,
        registration: registration,
        sector: sector,
        start_date: registration.admission_date
      )

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
