defmodule Sig.HR.Registrations.SuspensionsTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Suspensions
  alias Sig.HR.Registrations.Suspensions.Suspension

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Suspension{}} = Suspensions.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Suspension{}} = Suspensions.update_change(%Suspension{}, %{})
      assert %Ecto.Changeset{data: %Suspension{}} = Suspensions.update_change(%Suspension{})
    end
  end

  describe "get/2" do
    test "gets a suspension" do
      registration = insert(:employee_registration)
      %{id: id} = insert(:employee_suspension, org: registration.org, registration: registration)

      assert %Suspension{id: ^id} = Suspensions.get(registration, id)
    end

    test "suspension from another registration" do
      org = insert(:org)
      registration_1 = insert(:employee_registration, org: org)
      registration_2 = insert(:employee_registration, org: org)

      suspension = insert(:employee_suspension, org: org, registration: registration_1)

      assert Suspensions.get(registration_2, suspension.id) == nil
    end

    test "suspension doesn't exist" do
      registration = insert(:employee_registration)

      assert Suspensions.get(registration, UUID.generate()) == nil
    end
  end

  describe "list_by_registration/1" do
    test "lists suspensions by registration ordered by start_date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_suspension, org: org, registration: registration, start_date: ~D[2020-01-01])
      insert(:employee_suspension, org: org, registration: registration, start_date: ~D[2020-06-01])

      assert [
               %Suspension{start_date: ~D[2020-01-01]},
               %Suspension{start_date: ~D[2020-06-01]}
             ] = Suspensions.list_by_registration(registration)
    end

    test "registration has no suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      assert Suspensions.list_by_registration(registration) == []
    end
  end

  describe "create/1" do
    test "creates a suspension" do
      registration = insert(:employee_registration)

      attrs = %{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(3)
      }

      assert {:ok, %Suspension{id: id}} = Suspensions.create(registration, attrs)

      assert Repo.get_by(Suspension,
        id: id,
        org_id: registration.org_id,
        registration_id: registration.id,
        description: attrs[:description],
        start_date: attrs[:start_date],
        end_date: attrs[:end_date]
      )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Suspensions.create(registration, %{})

      assert errors_on(changeset) == %{
        description: ["can't be blank"],
        start_date: ["can't be blank"],
        end_date: ["can't be blank"]
      }
    end
  end

  describe "update/2" do
    test "updates a suspension" do
      suspension =
        insert(:employee_suspension,
          description: "Putting the beans before the rice",
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      attrs = %{
        description: "Pouring the beans before the rice",
        start_date: ~D[2021-01-02],
        end_date: ~D[2021-01-04]
      }

      assert {:ok, _return} = Suspensions.update(suspension, attrs)

      assert Repo.get_by(Suspension,
               id: suspension.id,
               org_id: suspension.org_id,
               registration_id: suspension.registration_id,
               description: attrs[:description],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date]
             )
    end
  end

  describe "subscribe_to_registration_suspensions/1" do
    test "subscribes to registration suspensions topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":suspensions"

      assert Suspensions.subscribe_to_registration_suspensions(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_suspensions, :suspensions}
      )

      assert_receive {:updated_registration_suspensions, :suspensions}
    end
  end

  describe "broadcast_registration_suspensions/1" do
    test "broadcasts suspensions from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert_list(2, :employee_suspension, org: org, registration: registration)
      insert(:employee_suspension)

      topic = "registration_id:" <> registration.id <> ":suspensions"

      @endpoint.subscribe(topic)

      assert Suspensions.broadcast_registration_suspensions(registration) == :ok

      assert_receive {:updated_registration_suspensions, received_suspensions}

      assert Enum.count(received_suspensions) == 2

      Enum.each(received_suspensions, fn suspension ->
        assert suspension.org_id == org.id
        assert suspension.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
