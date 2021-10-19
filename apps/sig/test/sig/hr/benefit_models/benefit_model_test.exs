defmodule Sig.HR.BenefitModels.BenefitModelTest do
  use Sig.DataCase

  alias Sig.Finance.HistoricalAmount
  alias Sig.HR.BenefitModels.BenefitModel

  describe "employee_benefit_models table constraints" do
    test "org_id not_null_violation" do
      benefit_model = %BenefitModel{
        description: Faker.Lorem.sentence(),
        type: random_enum_value(:employee_benefit_type),
        amount: Enum.random(400_00..600_00),
        amount_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_benefit_models\" violates not-null constraint/,
                   fn -> Repo.insert(benefit_model) end
    end

    test "org_id foreign_key_constraint" do
      benefit_model = %BenefitModel{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        type: random_enum_value(:employee_benefit_type),
        amount: Enum.random(400_00..600_00),
        amount_date: Faker.Date.backward(100)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_benefit_models_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(benefit_model) end
    end

    test "employee_benefit_models_amount_greater_than_zero constraint" do
      org = insert(:org)

      benefit_model = %BenefitModel{
        org_id: org.id,
        description: Faker.Lorem.sentence(),
        type: random_enum_value(:employee_benefit_type),
        amount: -1,
        amount_date: Faker.Date.backward(100)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_benefit_models_amount_greater_than_zero \(check_constraint\)/,
                   fn -> Repo.insert(benefit_model) end
    end

    test "employee_benefit_models_unique_description citext unique_constraint" do
      org = insert(:org)
      insert(:employee_benefit_model, org: org, description: "MODEL DESCRIPTION")

      benefit_model = %BenefitModel{
        org_id: org.id,
        description: "model description",
        type: random_enum_value(:employee_benefit_type),
        amount: Enum.random(400_00..600_00),
        amount_date: Faker.Date.backward(100)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_benefit_models_unique_description \(unique_constraint\)/,
                   fn -> Repo.insert(benefit_model) end
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      org_id = UUID.generate()
      description = Faker.Lorem.sentence()
      type = random_enum_value(:employee_benefit_type)
      amount = Enum.random(400_00..600_00)
      amount_date = Faker.Date.backward(100)

      attrs = %{
        org_id: org_id,
        description: description,
        type: type,
        amount: amount,
        amount_date: amount_date
      }

      assert changeset = BenefitModel.create_changeset(attrs)

      assert changeset.valid?

      assert %{
               org_id: ^org_id,
               description: ^description,
               type: ^type,
               amount: %Money{amount: ^amount, currency: :BRL},
               amount_date: ^amount_date,
               historical_amounts: [historical_amount_changeset]
             } = changeset.changes

      assert historical_amount_changeset.valid?
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        description: :invalid,
        type: :invalid,
        amount: :invalid,
        amount_date: :invalid
      }

      assert changeset = BenefitModel.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["is invalid"],
               amount_date: ["is invalid"],
               description: ["is invalid"],
               org_id: ["is invalid"],
               type: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = BenefitModel.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               amount_date: ["can't be blank"],
               description: ["can't be blank"],
               org_id: ["can't be blank"],
               type: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        type: random_enum_value(:employee_benefit_type),
        amount: Enum.random(400_00..600_00),
        amount_date: Faker.Date.backward(100),
        disabled_at: Date.utc_today(),
        historical_amounts: []
      }

      assert changeset = BenefitModel.create_changeset(attrs)

      assert changeset.valid?

      refute :disabled_at in Map.keys(changeset.changes)
      refute changeset.changes.historical_amounts == []
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        type: random_enum_value(:employee_benefit_type),
        amount: -1,
        amount_date: Faker.Date.backward(100)
      }

      assert changeset = BenefitModel.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than 0,00"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        description: String.duplicate("a", 256),
        type: random_enum_value(:employee_benefit_type),
        amount: Enum.random(400_00..600_00),
        amount_date: Faker.Date.backward(100)
      }

      assert changeset = BenefitModel.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["should be at most 255 character(s)"]
             }
    end

    test "description unique constraint" do
      org = insert(:org)
      insert(:employee_benefit_model, org: org, description: "model description")

      attrs = %{
        org_id: org.id,
        description: "MODEL DESCRIPTION",
        type: random_enum_value(:employee_benefit_type),
        amount: Enum.random(400_00..600_00),
        amount_date: Faker.Date.backward(100)
      }

      assert {:error, changeset} =
               attrs
               |> BenefitModel.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               description: ["has already been taken"]
             }
    end

    test "inserts employee benefit model with historical amount" do
      org = insert(:org)
      insert(:employee_benefit_model, org: org, description: "model description")

      attrs = %{
        org_id: org.id,
        description: Faker.Lorem.sentence(),
        type: random_enum_value(:employee_benefit_type),
        amount: Enum.random(400_00..600_00),
        amount_date: Faker.Date.backward(100)
      }

      assert {:ok, benefit_model} =
               attrs
               |> BenefitModel.create_changeset()
               |> Repo.insert()

      assert benefit_model.historical_amounts == [
               %HistoricalAmount{
                 date: attrs[:amount_date],
                 amount: %Money{amount: attrs[:amount], currency: :BRL}
               }
             ]
    end
  end

  describe "update_amount_changeset/2" do
    test "valid attrs" do
      benefit_model =
        insert(:employee_benefit_model,
          amount: 100_00,
          amount_date: ~D[2020-01-01],
          historical_amounts: [build(:historical_amount, date: ~D[2020-01-01], amount: 100_00)]
        )

      attrs = %{
        amount: 200_00,
        amount_date: ~D[2021-01-01]
      }

      assert changeset = BenefitModel.update_amount_changeset(benefit_model, attrs)

      assert changeset.valid?

      assert %{
               amount: %Money{amount: 200_00, currency: :BRL},
               amount_date: ~D[2021-01-01],
               historical_amounts: historical_amounts
             } = changeset.changes

      assert Enum.count(historical_amounts) == 2
    end

    test "ignores non permitted attrs" do
      benefit_model = insert(:employee_benefit_model, amount_date: ~D[2020-01-01], amount: 100_00)

      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        type: random_enum_value(:employee_benefit_type),
        amount: 200_00,
        amount_date: ~D[2020-06-01],
        disabled_at: Date.utc_today(),
        historical_amounts: []
      }

      assert changeset = BenefitModel.update_amount_changeset(benefit_model, attrs)

      assert changeset.valid?

      changes_keys = Map.keys(changeset.changes)

      assert Enum.count(changes_keys) == 3

      assert :amount in changes_keys
      assert :amount_date in changes_keys
      assert :historical_amounts in changes_keys

      refute changeset.changes.historical_amounts == []
    end

    test "add new entry to history when same amount and different date_amount" do
      benefit_model =
        insert(:employee_benefit_model,
          amount: 100_00,
          amount_date: ~D[2020-01-01],
          historical_amounts: [
            build(:historical_amount,
              date: ~D[2020-01-01],
              amount: %Money{amount: 100_00, currency: :BRL}
            )
          ]
        )

      attrs = %{
        amount: 200_00,
        amount_date: ~D[2020-06-01]
      }

      assert {:ok, return} =
               benefit_model
               |> BenefitModel.update_amount_changeset(attrs)
               |> Repo.update()

      assert return.amount_date == attrs[:amount_date]
      assert return.amount == %Money{amount: attrs[:amount], currency: :BRL}

      assert return.historical_amounts == [
               %HistoricalAmount{
                 amount: %Money{amount: 200_00, currency: :BRL},
                 date: ~D[2020-06-01]
               },
               %HistoricalAmount{
                 amount: %Money{amount: 100_00, currency: :BRL},
                 date: ~D[2020-01-01]
               }
             ]
    end

    test "do not alter history when same amount and date_amount" do
      benefit_model =
        insert(:employee_benefit_model,
          amount: 100_00,
          amount_date: ~D[2020-01-01],
          historical_amounts: [
            build(:historical_amount,
              date: ~D[2020-01-01],
              amount: %Money{amount: 100_00, currency: :BRL}
            )
          ]
        )

      attrs = %{
        amount: 100_00,
        amount_date: ~D[2020-01-01]
      }

      assert {:ok, return} =
               benefit_model
               |> BenefitModel.update_amount_changeset(attrs)
               |> Repo.update()

      assert return.amount_date == attrs[:amount_date]
      assert return.amount == %Money{amount: attrs[:amount], currency: :BRL}

      assert return.historical_amounts == [
               %HistoricalAmount{
                 amount: %Money{amount: 100_00, currency: :BRL},
                 date: ~D[2020-01-01]
               }
             ]
    end

    test "update history last entry when different amount and same date_amount" do
      benefit_model =
        insert(:employee_benefit_model,
          amount: 100_00,
          amount_date: ~D[2020-01-01],
          historical_amounts: [
            build(:historical_amount,
              date: ~D[2020-01-01],
              amount: %Money{amount: 100_00, currency: :BRL}
            )
          ]
        )

      attrs = %{
        amount: 200_00,
        amount_date: ~D[2020-01-01]
      }

      assert {:ok, return} =
               benefit_model
               |> BenefitModel.update_amount_changeset(attrs)
               |> Repo.update()

      assert return.amount_date == attrs[:amount_date]
      assert return.amount == %Money{amount: attrs[:amount], currency: :BRL}

      assert return.historical_amounts == [
               %HistoricalAmount{
                 amount: %Money{amount: 200_00, currency: :BRL},
                 date: ~D[2020-01-01]
               }
             ]
    end

    test "returns error when the date is before the last date in history" do
      last_entry = build(:historical_amount, date: ~D[2021-02-01], amount: 100)
      first_entry = build(:historical_amount, date: ~D[2021-01-01], amount: 200)

      model = insert(:employee_benefit_model, historical_amounts: [last_entry, first_entry])

      attrs = %{
        amount: 300,
        amount_date: ~D[2021-01-01]
      }

      assert {:error, changeset} =
               model
               |> BenefitModel.update_amount_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               amount_date: ["must be greater than the last date in history"]
             }
    end
  end
end
