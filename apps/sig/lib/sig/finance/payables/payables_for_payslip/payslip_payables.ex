defmodule Sig.Finance.Payables.PayablesForPayslip.PayslipPayables do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  # TODO: Add test
  def list_by_payslip(%Payslip{} = payslip) do
    PayslipPayable
    |> where(org_id: ^payslip.org_id)
    |> where(payslip_id: ^payslip.id)
    |> Repo.all()
  end

  # TODO: Add test
  def create(%Payslip{} = payslip, %Payable{} = payable, opts \\ []) do
    Multi.new()
    |> Multi.insert(:payslip_payable, %PayslipPayable{
      org_id: payslip.org_id,
      payslip_id: payslip.id,
      payable_id: payable.id
    })
    |> Multi.run(
      :set_payslip_payable_as_auto_adjustable_amount,
      fn _, %{payslip_payable: payslip_payable} ->
        if Keyword.get(opts, :is_auto_adjustable_amount, false) do
          set_as_auto_adjustable_amount(payslip, payable)
        else
          {:ok, payslip_payable}
        end
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{payslip_payable: payslip_payable}} -> {:ok, payslip_payable}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  def set_as_auto_adjustable_amount(_payslip, %Payable{is_fulfilled: true}) do
    {:error, "can't modify a fulfilled payable"}
  end

  def set_as_auto_adjustable_amount(
        %Payslip{org_id: org_id, id: payslip_id},
        %Payable{} = payable
      ) do
    Multi.new()
    |> Multi.update_all(
      :unset_existing,
      where(PayslipPayable,
        org_id: ^org_id,
        payslip_id: ^payslip_id,
        is_auto_adjustable_amount: true
      ),
      set: [is_auto_adjustable_amount: false]
    )
    |> Multi.update_all(
      :set_payslip_payable_as_auto_adjustable_amount,
      PayslipPayable
      |> where(
        org_id: ^org_id,
        payslip_id: ^payslip_id,
        payable_id: ^payable.id
      )
      |> select([payslip_payable], payslip_payable),
      set: [is_auto_adjustable_amount: true]
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{set_payslip_payable_as_auto_adjustable_amount: {1, [payslip_payable]}}} ->
        {:ok, payslip_payable}

      {:ok, %{set_payslip_payable_as_auto_adjustable_amount: {0, []}}} ->
        {:error, :not_found}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  def unset_as_auto_adjustable_amount(_payslip, %Payable{is_fulfilled: true}) do
    {:error, "can't modify a fulfilled payable"}
  end

  def unset_as_auto_adjustable_amount(%Payslip{} = payslip, %Payable{} = payable) do
    Repo.update_all(
      where(
        PayslipPayable,
        org_id: ^payslip.org_id,
        payslip_id: ^payslip.id,
        payable_id: ^payable.id
      ),
      set: [is_auto_adjustable_amount: false]
    )
    |> case do
      {1, _} -> :ok
      {0, _} -> {:error, :not_found}
    end
  end
end
