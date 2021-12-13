defmodule Sig.Organizations.PositionsTest do
  use Sig.DataCase

  alias Sig.Organizations.Positions
  alias Sig.Organizations.Position

  @endpoint SigLive.Endpoint

  describe "change/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Position{}} = Positions.change(%Position{}, %{})
    end
  end

  describe "change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Position{}} = Positions.change(%Position{})
      assert %Ecto.Changeset{data: %Position{}} = Positions.change(%{})
    end
  end

  describe "list/1" do
    test "lists positions by organization ordered by name" do
      org = insert(:org)

      insert(:org_position, org: org, name: "Z")
      insert(:org_position, org: org, name: "A")
      _to_ignore = insert(:org_position)

      assert [
               %Position{name: "A"},
               %Position{name: "Z"}
             ] = Positions.list(org)
    end

    test "when org has no position" do
      org = insert(:org)

      assert Positions.list(org) == []
    end
  end

  describe "get/2" do
    test "returns a position" do
      org = insert(:org)

      %{id: id} = position = insert(:org_position, org: org)

      assert %Position{id: ^id} = Positions.get(org, position.id)
    end

    test "when position doesn't belong to the org" do
      org = insert(:org)
      position = insert(:org_position)

      assert Positions.get(org, position.id) == nil
    end

    test "when position doesn't exist" do
      org = insert(:org)

      assert Positions.get(org, UUID.generate()) == nil
    end
  end

  describe "create/2" do
    test "creates a position" do
      org = insert(:org)

      attrs = %{name: "Kitchen"}

      assert {:ok, %Position{id: id, name: "Kitchen"}} = Positions.create(org, attrs)

      assert Repo.get_by(Position, org_id: org.id, id: id, name: "Kitchen")
    end

    test "returns changeset errors" do
      org = insert(:org)

      assert {:error, changeset} = Positions.create(org, %{})

      assert errors_on(changeset) == %{
               name: ["can't be blank"]
             }
    end
  end

  describe "update/2" do
    test "updates a position" do
      org = insert(:org)
      position = insert(:org_position, org: org, name: "Kitchen")

      attrs = %{name: "Cleaning"}

      assert {:ok, %Position{name: "Cleaning"}} = Positions.update(position, attrs)

      assert Repo.get_by(Position, org_id: org.id, id: position.id, name: "Cleaning")
    end

    test "returns changeset errors" do
      org = insert(:org)
      position = insert(:org_position, org: org, name: "Kitchen")

      attrs = %{name: nil}

      assert {:error, changeset} = Positions.update(position, attrs)

      assert errors_on(changeset) == %{
               name: ["can't be blank"]
             }

      assert Repo.get_by(Position, org_id: org.id, id: position.id, name: "Kitchen")
    end
  end

  describe "delete/1" do
    test "deletes a position" do
      org = insert(:org)
      %{id: id} = position = insert(:org_position, org: org)

      assert {:ok, %Position{id: ^id}} = Positions.delete(position)

      refute Repo.get_by(Position, org_id: org.id, id: position.id)
    end

    test "when position is being used by a registration" do
      org = insert(:org)
      position = insert(:org_position, org: org)

      insert(:employee_registration, org: org, position: position)

      assert Positions.delete(position) ==
               {:error, "Existem registros de funcionários associados"}

      assert Repo.get_by(Position, org_id: org.id, id: position.id)
    end
  end

  describe "subscribe_to_org_positions/1" do
    test "subscribes to org positions topic" do
      org = insert(:org)
      topic = "org_id:" <> org.id <> ":org_positions"

      assert Positions.subscribe_to_org_positions(org) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:new_org_position, :position})

      assert_receive {:new_org_position, :position}
    end
  end

  describe "broadcast_new_org_position/1" do
    test "broadcasts new positions from an org" do
      org = insert(:org)
      position = insert(:org_position, org: org)

      topic = "org_id:" <> org.id <> ":org_positions"

      @endpoint.subscribe(topic)

      assert Positions.broadcast_new_org_position(position) == :ok

      assert_receive {:new_org_position, received_position}

      assert received_position.id == position.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_updated_org_position/1" do
    test "broadcasts updated positions from an org" do
      org = insert(:org)
      position = insert(:org_position, org: org)

      topic = "org_id:" <> org.id <> ":org_positions"

      @endpoint.subscribe(topic)

      assert Positions.broadcast_updated_org_position(position) == :ok

      assert_receive {:updated_org_position, received_position}

      assert received_position.id == position.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_deleted_org_position/1" do
    test "broadcasts updated positions from an org" do
      org = insert(:org)
      position = insert(:org_position, org: org)

      topic = "org_id:" <> org.id <> ":org_positions"

      @endpoint.subscribe(topic)

      assert Positions.broadcast_deleted_org_position(position) == :ok

      assert_receive {:deleted_org_position, received_position}

      assert received_position.id == position.id

      @endpoint.unsubscribe(topic)
    end
  end
end
