defmodule Sig.HR do
  alias Sig.HR.BenefitModels
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Categories
  alias Sig.HR.Payslips.Items
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

  defdelegate list_benefit_models(org), to: BenefitModels, as: :list

  defdelegate list_benefits_by_registration(registration), to: Benefits, as: :list_by_registration
  defdelegate get_benefit(registration, id), to: Benefits, as: :get
  defdelegate create_benefit(registration, attrs), to: Benefits, as: :create
  defdelegate create_benefit_from_model(registration, attrs), to: Benefits, as: :create_from_model
  defdelegate update_benefit_amount(benefit, attrs), to: Benefits, as: :update_benefit_amount
  defdelegate finalize_benefit(benefit, attrs), to: Benefits, as: :finalize
  defdelegate subscribe_to_registration_benefits(registration), to: Benefits
  defdelegate broadcast_registration_benefits(registration), to: Benefits
  defdelegate create_benefit_change(attrs \\ %{}), to: Benefits, as: :create_change

  defdelegate create_benefit_from_model_change(attrs \\ %{}),
    to: Benefits,
    as: :create_from_model_change

  defdelegate update_benefit_amount_change(benefit, attrs),
    to: Benefits,
    as: :update_benefit_amount_change

  defdelegate finalize_benefit_change(benefit, attrs \\ %{}), to: Benefits, as: :finalize_change

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

  defdelegate list_payslip_categories(org_id), to: Categories, as: :list

  defdelegate list_payslip_recurring_item_models(org), to: RecurringItemModels, as: :list

  defdelegate list_recurring_payslip_items_by_registration(registraion, opts \\ []),
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

  defdelegate create_payslip(registration, attrs), to: Payslips, as: :create
  defdelegate list_payslips_by_registration(registration), to: Payslips, as: :list_by_registration
  defdelegate get_payslip(registration, id), to: Payslips, as: :get
  defdelegate create_payslip_change(attrs \\ %{}), to: Payslips, as: :create_change
  defdelegate subscribe_to_registration_payslips(registration), to: Payslips
  defdelegate broadcast_registration_payslips(registration), to: Payslips
  defdelegate subscribe_to_payslip(payslip), to: Payslips
  defdelegate unsubscribe_from_payslip(payslip), to: Payslips
  defdelegate broadcast_payslip(registration), to: Payslips

  defdelegate list_items_by_payslip(payslip), to: Items, as: :list_by_payslip
  defdelegate get_payslip_item(payslip, id), to: Items, as: :get
  defdelegate fetch_payslip_item(payslip, id), to: Items, as: :fetch
  defdelegate create_payslip_item(payslip, attrs), to: Items
  defdelegate create_payslip_outside_item(payslip, attrs), to: Items, as: :create_outside_item
  defdelegate update_payslip_item_amount(payslip, item, attrs), to: Items, as: :update_amount
  defdelegate delete_payslip_item(payslip, item), to: Items, as: :delete_item
  defdelegate create_payslip_item_change(attrs \\ %{}), to: Items, as: :create_change

  defdelegate create_payslip_outside_item_change(attrs \\ %{}),
    to: Items,
    as: :create_outside_item_change

  defdelegate update_payslip_item_amount_change(item, attrs \\ %{}),
    to: Items,
    as: :update_amount_change

  defdelegate subscribe_to_payslip_items(payslip), to: Items
  defdelegate unsubscribe_from_payslip_items(payslip), to: Items
  defdelegate broadcast_payslip_items(payslip), to: Items
  defdelegate sum_payments_in_advance_items_by_payslip(payslip), to: Items
end
