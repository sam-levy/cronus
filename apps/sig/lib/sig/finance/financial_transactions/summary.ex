defmodule Sig.Finance.FinancialTransactions.Summary do
  @moduledoc """
  This module is temporary and should be removed as soon as the bank account
  management feature is fully implemented.
  """

  import Ecto.Query
  import Sig.Enums.FinancialTransaction, only: [bank_types: 0]

  alias Sig.Entities.Companies.Company
  alias Sig.Finance.FinancialTransactions, as: FT
  alias Sig.Organizations.Org
  alias Sig.Repo

  @accounts_to_display [
    "Brad Pe",
    "CEF Pe",
    "Brad SM",
    "CEF SM",
    "Brad Sz",
    "CEF Sz",
    "Brad MC",
    "CEF MC"
  ]

  def accounts_to_display, do: @accounts_to_display

  def build(%Org{} = org, %MapSet{} = ft_ids), do: do_build(org, ft_ids)
  def build(%Org{} = org, ft_ids) when is_list(ft_ids), do: do_build(org, ft_ids)

  defp do_build(org, ft_ids) do
    financial_transactions = list_for_bank_summary(org, ft_ids)

    Enum.reduce(financial_transactions, %{total_amount_sum: Money.new(0)}, fn
      transaction, acc when transaction.bank_account.name in @accounts_to_display ->
        Enum.reduce(transaction.payables, acc, fn payable, acc ->
          [assigned_company] = payable.payslip.registration.assigned_companies

          key =
            {transaction.clearing_date, transaction.bank_account.name,
             assigned_company.trade_name}

          value = Map.get(acc, key, %{payable_ids: [], amount_sum: Money.new(0)})

          amount_sum = Money.add(value.amount_sum, payable.amount)

          acc
          |> Map.put(key, %{
            value
            | payable_ids: [payable.id | value.payable_ids],
              amount_sum: amount_sum
          })
          |> Map.put(:total_amount_sum, Money.add(acc.total_amount_sum, payable.amount))
        end)

      _, acc ->
        acc
    end)
  end

  defp list_for_bank_summary(org, ft_ids) do
    org
    |> FT.query_by()
    |> FT.filter_by(:id, ft_ids)
    |> FT.filter_by(:entry_type, :debit)
    |> FT.filter_by(:type, bank_types())
    |> FT.reject_nil(:clearing_date)
    |> FT.shallow_preload([:bank_account, :payables])
    |> where([payables: payable], payable.target == :payslip)
    |> join(:left, [payables: payable], payslip in assoc(payable, :payslip), as: :payslips)
    |> join(:left, [payslips: payslip], registration in assoc(payslip, :registration),
      as: :registrations
    )
    |> join(
      :inner_lateral,
      [payslips: payslip, registrations: registration],
      ca in fragment(
        "SELECT * FROM employee_company_assignments AS ca WHERE ca.registration_id = ? AND ca.start_date <= ? LIMIT 1",
        registration.id,
        payslip.start_date
      ),
      as: :company_assignments
    )
    |> join(:left, [company_assignments: company_assignment], assigned_company in Company,
      on: assigned_company.entity_id == company_assignment.assigned_company_id,
      as: :assigned_companies
    )
    |> preload(
      [
        payables: payables,
        payslips: payslips,
        registrations: registrations,
        assigned_companies: assigned_companies
      ],
      payables:
        {payables,
         [
           payslip:
             {payslips, [registration: {registrations, [assigned_companies: assigned_companies]}]}
         ]}
    )
    |> Repo.all()
  end
end
