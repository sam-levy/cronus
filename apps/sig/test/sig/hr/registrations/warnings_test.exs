defmodule Sig.HR.Registrations.WarningsTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Warnings
  alias Sig.HR.Registrations.Warnings.Warning

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Warning{}} = Warnings.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Warning{}} = Warnings.update_change(%Warning{}, %{})
      assert %Ecto.Changeset{data: %Warning{}} = Warnings.update_change(%Warning{})
    end
  end

  describe "get/2" do
    test "gets a warning" do
      registration = insert(:employee_registration)
      %{id: id} = insert(:employee_warning, org: registration.org, registration: registration)

      assert %Warning{id: ^id} = Warnings.get(registration, id)
    end

    test "warning from another registration" do
      org = insert(:org)
      registration_1 = insert(:employee_registration, org: org)
      registration_2 = insert(:employee_registration, org: org)

      warning = insert(:employee_warning, org: org, registration: registration_1)

      assert Warnings.get(registration_2, warning.id) == nil
    end

    test "warning doesn't exist" do
      registration = insert(:employee_registration)

      assert Warnings.get(registration, UUID.generate()) == nil
    end
  end

  describe "list_by_registration/1" do
    test "lists warnings by registration ordered by date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_warning, org: org, registration: registration, date: ~D[2020-01-01])
      insert(:employee_warning, org: org, registration: registration, date: ~D[2020-06-01])

      assert [
               %Warning{date: ~D[2020-01-01]},
               %Warning{date: ~D[2020-06-01]}
             ] = Warnings.list_by_registration(registration)
    end

    test "registration has no warning" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      assert Warnings.list_by_registration(registration) == []
    end
  end

  describe "create/1" do
    test "creates a warning" do
      registration = insert(:employee_registration)

      attrs = %{
        org_id: registration.org_id,
        registration_id: registration.id,
        date: Date.utc_today(),
        description: Faker.Lorem.paragraph(1)
      }

      assert {:ok, %Warning{id: id}} = Warnings.create(registration, attrs)

      assert Repo.get_by(Warning,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               date: attrs[:date],
               description: attrs[:description]
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Warnings.create(registration, %{})

      assert errors_on(changeset) == %{
               date: ["can't be blank"],
               description: ["can't be blank"]
             }
    end
  end

  describe "update/2" do
    test "updates a warning" do
      warning =
        insert(:employee_warning,
          date: ~D[2020-01-01],
          description: "Putting the beans before the rice"
        )

      attrs = %{date: ~D[2021-01-02], description: "Pouring the beans before the rice"}

      assert {:ok, _return} = Warnings.update(warning, attrs)

      assert Repo.get_by(Warning,
               id: warning.id,
               org_id: warning.org_id,
               registration_id: warning.registration_id,
               date: attrs[:date],
               description: attrs[:description]
             )
    end

    test "returns changeset errors" do
      warning = insert(:employee_warning)

      attrs = %{description: nil}

      assert {:error, changeset} = Warnings.update(warning, attrs)

      assert errors_on(changeset) == %{
        description: ["can't be blank"]
      }
    end
  end

  describe "subscribe_to_registration_warnings/1" do
    test "subscribes to registration warnings topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":warnings"

      assert Warnings.subscribe_to_registration_warnings(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_warnings, :warnings}
      )

      assert_receive {:updated_registration_warnings, :warnings}
    end
  end

  describe "broadcast_registration_warnings/1" do
    test "broadcasts warnings from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert_list(2, :employee_warning, org: org, registration: registration)
      insert(:employee_warning)

      topic = "registration_id:" <> registration.id <> ":warnings"

      @endpoint.subscribe(topic)

      assert Warnings.broadcast_registration_warnings(registration) == :ok

      assert_receive {:updated_registration_warnings, received_warnings}

      assert Enum.count(received_warnings) == 2

      Enum.each(received_warnings, fn warning ->
        assert warning.org_id == org.id
        assert warning.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
