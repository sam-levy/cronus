defmodule SigLive.AccountsPayable.PayFooter do
  use SigLive, :surface_live_component

  import Sig.Enums.FinancialTransaction, only: [is_bank_type: 1]

  alias Sig.Finance

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    HiddenInput,
    Checkbox,
    Label,
    DateInput,
    TextInput,
    Select,
    Field,
    Submit
  }

  alias SigLive.Components.{FooterModal, LabelWithError}

  prop org, :struct, required: true
  prop org_bank_accounts, :list, required: true
  prop message, :string, default: nil
  prop selected_payables, :map, required: true
  prop selected_method, :atom, required: true
  prop selected_amount_sum, :struct, required: true
  prop close_event, :event, required: true
  prop close_fun, :fun, required: true

  data not_cleared, :boolean, default: false
  data bank_account_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{selected_payables: selected_payables} = assigns

    socket = assign(socket, assigns)

    {:ok,
     assign(socket,
       selected_payables_count: Enum.count(selected_payables),
       changeset: build_changeset(socket)
     )}
  end

  defp build_changeset(socket) do
    %{selected_payables: selected_payables} = socket.assigns

    today = Date.utc_today()

    Finance.pay_payables_change(%{
      description: build_description(selected_payables),
      placement_date: today,
      clearing_date: today,
      bank_account_id: get_check_debit_bank_account_id(selected_payables)
    })
  end

  defp get_check_debit_bank_account_id(selected_paybles) do
    with 1 <- Enum.count(selected_paybles),
    %{financial_transaction_type: :check, check_debit_bank_account_id: account_id} <- get_single_payable(selected_paybles) do
      account_id
    else
      _ -> nil
    end
  end

  @impl true
  def handle_event("form_change", %{"attrs" => params}, socket) do
    {:noreply,
     socket
     |> handle_clearing_date(params)
     |> assign(:bank_account_id, params["bank_account_id"])}
  end

  @impl true
  def handle_event("save", %{"attrs" => params}, socket) do
    %{org: org, selected_method: selected_method, selected_payables: selected_payables} =
      socket.assigns

    params =
      params
      |> Map.put("type", selected_method)
      |> Map.put("payable_ids", Map.keys(selected_payables))

    with changeset <- Finance.pay_payables_change(params),
         {:ok, _attrs} <- apply_action(changeset, :insert),
         {:ok, financial_transaction} <- Finance.pay_payables(org, changeset.changes) do
      Finance.broadcast_new_financial_transaction(financial_transaction)
      send(self(), {:flash, :info, "Pagamento efetuado"})
      socket.assigns.close_fun.()

      {:noreply, socket}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp handle_clearing_date(socket, %{"not_cleared" => "true"} = params) do
    changeset =
      params
      |> Map.put("clearing_date", nil)
      |> Finance.pay_payables_change()

    assign(socket, changeset: changeset, not_cleared: true)
  end

  defp handle_clearing_date(socket, %{"not_cleared" => "false"} = params) do
    changeset =
      params
      |> Map.put("clearing_date", get_clearing_date(socket, params))
      |> Finance.pay_payables_change()

    assign(socket, changeset: changeset, not_cleared: false)
  end

  def get_clearing_date(socket, params) do
    previous_placement_date = socket.assigns.changeset.changes.placement_date

    with {:ok, new_placement_date} <- Date.from_iso8601(params["placement_date"]),
         true <- previous_placement_date == new_placement_date,
         true <- params["clearing_date"] != nil do
      params["clearing_date"]
    else
      {:error, _} -> previous_placement_date
      false -> params["placement_date"]
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <FooterModal id="footer_pay_modal" close={@close_event}>
        <:title_content>
          {#if @selected_payables_count > 1}
            Pagamento em Lote

            <span :if={@selected_payables_count > 1} class="ml-1 text-gray-500 text-sm font-light italic">
              {@selected_payables_count} pagáveis selecionados
            </span>
          {#else}
            Pagamento
          {/if}
        </:title_content>

        <Form for={@changeset} change="form_change" submit="save" opts={autocomplete: "off"}>
          <Field name={:description} class="form-field">
            <LabelWithError>Descrição</LabelWithError>
            <TextInput class="form-input"/>
          </Field>

          <div class="flex space-x-4 form-field">
            <Field name={:type} class="flex-1">
              <LabelWithError>Forma de Pagamento</LabelWithError>
              <TextInput value={capitalize_type(@selected_method)} {...props_for(:type)}/>
            </Field>

            <Field :if={@selected_method == :check} name={:check_number} class="flex-1">
              <LabelWithError>Número do Cheque</LabelWithError>
              <TextInput {...props_for(:check_number, @selected_payables)}/>
            </Field>

            <Field name={:amount} class="flex-1">
              <LabelWithError>Valor</LabelWithError>
              <TextInput value={@selected_amount_sum} {...props_for(:amount)}/>
            </Field>
          </div>

          <Field :if={single_bank_transfer_payable?(@selected_payables)} name={:credit_bank_account} class="form-field">
            <LabelWithError>Conta para Depósito</LabelWithError>
            <TextInput
              value={format_credit_bank_account(@selected_payables)}
              {...props_for(:credit_bank_account)}
            />
          </Field>

          <Field :if={get_single_bank_transfer_payable_pix_key(@selected_payables)} name={:credit_bank_account_pix_key} class="form-field">
            <LabelWithError>Chave Pix</LabelWithError>
            <TextInput
              value={get_single_bank_transfer_payable_pix_key(@selected_payables)}
              {...props_for(:credit_bank_account_pix_key)}
            />
          </Field>

          <div class="flex space-x-4 form-field">
            <Field name={:placement_date} class="flex-1">
              <LabelWithError>Data de Pagamento</LabelWithError>
              <DateInput class="form-input"/>
            </Field>

            <Field name={:clearing_date} class="flex-1">
              <div class="flex items-top justify-between">
                <LabelWithError>Liquidação</LabelWithError>

                <Field name={:not_cleared} class="ml-3">
                  <div class="flex items-center">
                    <Checkbox class="form-checkbox"/>
                    <Label class="form-side-label">Não liquidado</Label>
                  </div>
                </Field>
              </div>

              <DateInput :if={@not_cleared == false} class="form-input"/>
              <TextInput :if={@not_cleared} {...props_for(:disabled_clearing_date)}/>
            </Field>
          </div>

          <div class="flex items-end justify-end space-x-4 form-field">
            <Field :if={is_bank_type(@selected_method)} name={:bank_account_id} class="flex-1">
              <LabelWithError>Conta de Débito</LabelWithError>
              <Select
                options={bank_accounts_for_select(@org_bank_accounts)}
                prompt=""
                {...props_for(:bank_account_id, @selected_method, @selected_payables)}
              />

              <HiddenInput
                :if={@selected_method == :check}
                value={get_check_debit_bank_account_id(@selected_payables)}
              />
            </Field>

            <Submit class="w-28 btn-blue flex justify-center" label="Pagar" opts={phx_disable_with: "Adicionando..."}/>
          </div>

          <div :if={@message} class="form-error-tag mb-3">{@message}</div>
        </Form>
      </FooterModal>
    </div>
    """
  end

  defp single_bank_transfer_payable?(selected_paybles) do
    with 1 <- Enum.count(selected_paybles),
         %{financial_transaction_type: :bank_transfer} <- get_single_payable(selected_paybles) do
      true
    else
      _ -> false
    end
  end

  defp get_single_bank_transfer_payable_pix_key(selected_paybles) do
    with 1 <- Enum.count(selected_paybles),
         %{financial_transaction_type: :bank_transfer, credit_bank_account: %{pix_key: pix_key}} <-
           get_single_payable(selected_paybles) do
      pix_key
    else
      _ -> nil
    end
  end

  defp build_description(selected_paybles) do
    with 1 <- Enum.count(selected_paybles),
         %{target: :payslip} = payable <- get_single_payable(selected_paybles) do
      "#{payable.description} #{payable.employee.name}"
    else
      _ -> ""
    end
  end

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(:amount), do: @input_disabled
  defp props_for(:type), do: @input_disabled
  defp props_for(:credit_bank_account), do: @input_disabled
  defp props_for(:credit_bank_account_pix_key), do: @input_disabled
  defp props_for(:disabled_clearing_date), do: @input_disabled
  defp props_for(_field), do: @input_enabled

  defp props_for(:check_number, payables) do
    %{check_number: check_number} = get_single_payable(payables)

    [value: check_number, opts: [disabled: true], class: ["form-input-disabled"]]
  end

  defp props_for(:bank_account_id, :check, payables) do
    %{check_debit_bank_account_id: account_id} = get_single_payable(payables)

    [selected: account_id, opts: [disabled: true], class: ["form-input-disabled"]]
  end

  defp props_for(:bank_account_id, _method, _payables), do: @input_enabled

  defp format_credit_bank_account(payables) do
    %{credit_bank_account: account} = get_single_payable(payables)

    format_bank_account(account)
  end

  defp get_single_payable(payables), do: payables |> Map.values() |> hd()
end
