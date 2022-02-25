defmodule Sig.Factory do
  use Sig.Factories.CompanyFactory
  use Sig.Factories.EntityFactory
  use Sig.Factories.IndividualFactory
  use Sig.Factories.OrgFactory
  use Sig.Factories.SectorFactory
  use Sig.Factories.PositionFactory
  use Sig.Factories.RegistrationFactory
  use Sig.Factories.UserFactory
  use Sig.Factories.SalaryFactory
  use Sig.Factories.RegistrationPositionFactory
  use Sig.Factories.CompanyAssignmentFactory
  use Sig.Factories.HistoricalAmountFactory
  use Sig.Factories.EmployeeBenefitModelFactory
  use Sig.Factories.EmployeeBenefitFactory
  use Sig.Factories.WarningFactory
  use Sig.Factories.SuspensionFactory
  use Sig.Factories.LeavePeriodFactory
  use Sig.Factories.OvertimeFactory
  use Sig.Factories.PayslipFactory
  use Sig.Factories.PayslipItemFactory
  use Sig.Factories.PayslipCategoryFactory
  use Sig.Factories.PayslipGroupFactory
  use Sig.Factories.PayslipTemplateFactory
  use Sig.Factories.PayslipTemplateItemFactory
  use Sig.Factories.PayslipRecurringItemModelFactory
  use Sig.Factories.EmployeeRegistraionRecurringPayslipItemFactory
  use Sig.Factories.BankAccountFactory
  use Sig.Factories.EntityBankAccountFactory
  use Sig.Factories.PayableFactory
  use Sig.Factories.PayslipPayableFactory
  use Sig.Factories.FinancialTransactionFactory
  use Sig.Factories.BankTransactionFactory

  def build(factory_name, attributes \\ []) do
    factory_name |> factory(attributes) |> struct(attributes)
  end

  def insert(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Sig.Repo.insert!()
  end

  def build_list(amount, factory_name, attributes \\ []) do
    Stream.repeatedly(fn -> build(factory_name, attributes) end) |> Enum.take(amount)
  end

  def insert_list(amount, factory_name, attributes \\ []) do
    Stream.repeatedly(fn -> insert(factory_name, attributes) end) |> Enum.take(amount)
  end

  def factory(factory_name, _attributes), do: factory(factory_name)

  def random_enum_value(:entry_type), do: random_enum_value(Sig.EntryType)
  def random_enum_value(enum), do: Enum.random(enum.__enums__())

  def random_string_number, do: 100..1_000_000 |> Enum.random() |> to_string()

  def random_past_date, do: 1..500_000 |> Enum.random() |> Faker.Date.backward()

  defp sequence(fun) when is_function(fun, 1) do
    fun.(System.unique_integer([:positive, :monotonic]))
  end
end
