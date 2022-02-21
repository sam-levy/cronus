defmodule Sig.HR.Registrations.SalariesTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.Salaries
  alias Sig.HR.Registrations.Salaries.Salary

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Salary{}} = Salaries.create_change()
    end
  end

  describe "update_change/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Salary{}} = Salaries.update_change(%Salary{}, %{})

      assert %Ecto.Changeset{data: %Salary{}} = Salaries.update_change(%Salary{})
    end
  end

  describe "update/2" do
    test "updates a salary" do
      %{id: salary_id} =
        salary = insert(:employee_salary, start_date: ~D[2021-01-01], amount: 2_000_00)

      attrs = %{
        start_date: ~D[2021-02-01],
        amount: 2_500_00
      }

      assert {:ok, %Salary{id: ^salary_id}} = Salaries.update(salary, attrs)

      assert Repo.get_by(Salary,
               org_id: salary.org_id,
               id: salary_id,
               start_date: ~D[2021-02-01],
               amount: 2_500_00
             )
    end

    test "when `start_date` is before the registration `admission_date`" do
      org = insert(:org)

      admission_date = ~D[2021-01-01]

      registration = insert(:employee_registration, org: org, admission_date: admission_date)

      salary =
        insert(:employee_salary,
          org: org,
          registration: registration,
          start_date: admission_date,
          amount: 2_000_00
        )

      attrs = %{
        start_date: ~D[2020-12-01],
        amount: 2_500_00
      }

      assert Salaries.update(salary, attrs) ==
               {:error, "A data inicial deve ser igual ou posterir a data de registro"}

      assert Repo.get_by(Salary,
               org_id: salary.org_id,
               id: salary.id,
               start_date: ~D[2021-01-01],
               amount: 2_000_00
             )
    end

    test "returns changeset errors" do
      org = insert(:org)

      admission_date = ~D[2021-01-01]

      registration = insert(:employee_registration, org: org, admission_date: admission_date)

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: admission_date,
        amount: 2_000_00
      )

      salary_2 =
        insert(:employee_salary,
          org: org,
          registration: registration,
          start_date: ~D[2021-02-01],
          amount: 2_500_00
        )

      attrs = %{
        start_date: admission_date,
        amount: 3_000_00
      }

      assert {:error, changeset} = Salaries.update(salary_2, attrs)

      assert errors_on(changeset) == %{
               start_date: ["has already been taken"]
             }

      assert Repo.get_by(Salary,
               org_id: salary_2.org_id,
               id: salary_2.id,
               start_date: ~D[2021-02-01],
               amount: 2_500_00
             )
    end
  end

  describe "delete/1" do
    test "deletes a salary" do
      start_date = ~D[2022-01-01]
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: start_date)

      %{id: salary_1_id} =
        insert(:employee_salary, org: org, registration: registration, start_date: start_date)

      %{id: salary_2_id} =
        salary_2 =
        insert(:employee_salary, org: org, registration: registration, start_date: ~D[2022-06-01])

      assert {:ok, %Salary{id: ^salary_2_id}} = Salaries.delete(salary_2)

      refute Repo.get_by(Salary, org_id: org.id, id: salary_2_id)

      assert Repo.get_by(Salary, org_id: org.id, id: salary_1_id)
    end

    test "when registration has only one salary" do
      start_date = ~D[2022-01-01]
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: start_date)

      %{id: salary_id} =
        salary =
        insert(:employee_salary, org: org, registration: registration, start_date: start_date)

      assert Salaries.delete(salary) == {:error, "Deve existir pelo menos um salário"}

      assert Repo.get_by(Salary, org_id: org.id, id: salary_id)
    end
  end

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

  describe "get/2" do
    test "gets a salary" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: salary_id} = insert(:employee_salary, org: org, registration: registration)

      assert %Salary{id: ^salary_id} = Salaries.get(registration, salary_id)
    end

    test "invalid id" do
      registration = insert(:employee_registration)

      assert Salaries.get(registration, UUID.generate()) == nil
    end
  end

  describe "fetch/2" do
    test "fetches a salary" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: salary_id} = insert(:employee_salary, org: org, registration: registration)

      assert {:ok, %Salary{id: ^salary_id}} = Salaries.fetch(registration, salary_id)
    end

    test "invalid id" do
      registration = insert(:employee_registration)

      assert Salaries.fetch(registration, UUID.generate()) == {:error, :not_found}
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
