defmodule Sig.HR.Registrations.SalariesTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.Salaries
  alias Sig.HR.Registrations.Salaries.Salary

  @endpoint SigLive.Endpoint

  describe "list_by_registration/1" do
    test "lists salaries by registration ordered by start_date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: ~D[2020-01-01],
        amount: 1_500_00
      )

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: ~D[2020-06-01],
        amount: 1_800_00
      )

      assert [
               %Salary{start_date: ~D[2020-01-01]},
               %Salary{start_date: ~D[2020-06-01]}
             ] = Salaries.list_by_registration(registration)
    end
  end

  describe "in_effect_on_date/1" do
    test "gets the current salary" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: ~D[2021-01-01],
        amount: 1_500_00
      )

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: ~D[2021-06-01],
        amount: 1_800_00
      )

      assert %Salary{amount: %Money{amount: 1_500_00}} =
               Salaries.in_effect_on_date(registration, ~D[2021-04-01])

      assert %Salary{amount: %Money{amount: 1_800_00}} =
               Salaries.in_effect_on_date(registration, ~D[2021-06-01])

      assert Salaries.in_effect_on_date(registration, ~D[2020-01-01]) == nil
    end
  end

  describe "subscribe_to_registration_salaries/1" do
    test "subscribes to registration salaries topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":salaries"

      assert Salaries.subscribe_to_registration_salaries(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_salaries, :salaries}
      )

      assert_receive {:updated_registration_salaries, :salaries}
    end
  end

  describe "broadcast_registration_salaries/1" do
    test "broadcasts salaries from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      # Right salaries
      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: registration.admission_date
      )

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: Date.add(registration.admission_date, 180)
      )

      _wrong_salaries = insert_list(2, :employee_salary)

      topic = "registration_id:" <> registration.id <> ":salaries"

      @endpoint.subscribe(topic)

      assert Salaries.broadcast_registration_salaries(registration) == :ok

      assert_receive {:updated_registration_salaries, received_salaries}

      assert Enum.count(received_salaries) == 2

      Enum.each(received_salaries, fn salary ->
        assert salary.org_id == org.id
        assert salary.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
