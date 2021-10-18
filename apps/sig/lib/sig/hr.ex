defmodule Sig.HR do
  alias Sig.HR.Payslips.Categories
  alias Sig.HR.Payslips.RecurringItemModels
  alias Sig.HR.Registrations
  alias Sig.HR.Registrations.Salaries
  alias Sig.HR.Registrations.Benefits
  alias Sig.HR.Registrations.Warnings
  alias Sig.HR.Registrations.Suspensions
  alias Sig.HR.Registrations.LeavePeriods
  alias Sig.HR.Registrations.RecurringPayslipItems

  defdelegate create_registration_change(attrs \\ %{}), to: Registrations, as: :create_change

  defdelegate update_registration_change(registration, attrs \\ %{}),
    to: Registrations,
    as: :update_change

  defdelegate resignation_registration_change(registration, attrs),
    to: Registrations,
    as: :resignation_change

  defdelegate create_registration(org, individual, attrs), to: Registrations, as: :create
  defdelegate update_registration(individual, attrs), to: Registrations, as: :update

  defdelegate list_registrations_by_individual(individual),
    to: Registrations,
    as: :list_by_individual

  defdelegate get_registration(individual, id), to: Registrations, as: :get
  defdelegate subscribe_to_individual_registrations(individual), to: Registrations
  defdelegate broadcast_individual_registrations(indiviual), to: Registrations

  defdelegate list_salaries_by_registration(registration), to: Salaries, as: :list_by_registration
  defdelegate create_salary(registration, attrs), to: Salaries, as: :create
  defdelegate subscribe_to_registration_salaries(registration), to: Salaries
  defdelegate broadcast_registration_salaries(registration), to: Salaries
  defdelegate create_salary_change(attrs \\ %{}), to: Salaries, as: :create_change

  defdelegate list_benefits_by_registration(registration), to: Benefits, as: :list_by_registration
  defdelegate get_benefit(registration, id), to: Benefits, as: :get
  defdelegate create_benefit(registration, attrs), to: Benefits, as: :create
  defdelegate create_benefit_from_model(registration, attrs), to: Benefits, as: :create_from_model
  defdelegate update_benefit(benefit, attrs), to: Benefits, as: :update
  defdelegate subscribe_to_registration_benefits(registration), to: Benefits
  defdelegate broadcast_registration_benefits(registration), to: Benefits
  defdelegate create_benefit_change(attrs \\ %{}), to: Benefits, as: :create_change
  defdelegate update_benefit_change(benefit, attrs \\ %{}), to: Benefits, as: :update_change

  defdelegate list_warnings_by_registration(registration), to: Warnings, as: :list_by_registration
  defdelegate get_warning(registration, id), to: Warnings, as: :get
  defdelegate create_warning(registration, attrs), to: Warnings, as: :create
  defdelegate update_warning(warning, attrs), to: Warnings, as: :update
  defdelegate subscribe_to_registration_warnings(registration), to: Warnings
  defdelegate broadcast_registration_warnings(registration), to: Warnings
  defdelegate create_warning_change(attrs \\ %{}), to: Warnings, as: :create_change
  defdelegate update_warning_change(warning, attrs \\ %{}), to: Warnings, as: :update_change

  defdelegate list_suspensions_by_registration(registration),
    to: Suspensions,
    as: :list_by_registration

  defdelegate get_suspension(registration, id), to: Suspensions, as: :get
  defdelegate create_suspension(registration, attrs), to: Suspensions, as: :create
  defdelegate update_suspension(suspension, attrs), to: Suspensions, as: :update
  defdelegate subscribe_to_registration_suspensions(registration), to: Suspensions
  defdelegate broadcast_registration_suspensions(registration), to: Suspensions
  defdelegate create_suspension_change(attrs \\ %{}), to: Suspensions, as: :create_change

  defdelegate update_suspension_change(suspension, attrs \\ %{}),
    to: Suspensions,
    as: :update_change

  defdelegate list_leave_periods_by_registration(registration),
    to: LeavePeriods,
    as: :list_by_registration

  defdelegate list_leave_period_types, to: LeavePeriods
  defdelegate get_leave_period(registration, id), to: LeavePeriods, as: :get
  defdelegate create_leave_period(registration, attrs), to: LeavePeriods, as: :create
  defdelegate update_leave_period(leave_period, attrs), to: LeavePeriods, as: :update
  defdelegate subscribe_to_registration_leave_periods(registration), to: LeavePeriods
  defdelegate broadcast_registration_leave_periods(registration), to: LeavePeriods
  defdelegate create_leave_period_change(attrs \\ %{}), to: LeavePeriods, as: :create_change

  defdelegate update_leave_period_change(leave_period, attrs \\ %{}),
    to: LeavePeriods,
    as: :update_change

  defdelegate list_payslip_categories(org), to: Categories, as: :list

  defdelegate list_payslip_recurring_item_models(org), to: RecurringItemModels, as: :list

  defdelegate list_recurring_payslip_items_by_registration(registraion),
    to: RecurringPayslipItems,
    as: :list_by_registration

  defdelegate create_recurring_payslip_item(registraion, attrs, type),
    to: RecurringPayslipItems,
    as: :create

  defdelegate delete_recurring_payslip_item(registraion, id),
    to: RecurringPayslipItems,
    as: :delete

  defdelegate subscribe_to_registration_recurring_payslip_items(registration),
    to: RecurringPayslipItems

  defdelegate broadcast_registration_recurring_payslip_items(registration),
    to: RecurringPayslipItems

  defdelegate create_recurring_payslip_item_change(attrs \\ %{}, type),
    to: RecurringPayslipItems,
    as: :create_change
end
