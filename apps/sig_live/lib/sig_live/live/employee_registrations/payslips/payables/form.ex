defmodule SigLive.EmployeeRegistrations.Payslips.Payables.Form do
  use SigLive, :surface_live_component

  alias Sig.Finance
  alias Sig.Entities

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    DateInput,
    TextInput,
    Select,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.{Modal, Switch}

  @form_states [:new_mode, :edit_mode, :show_mode, :closed]

  prop registration, :struct, required: true
  prop payslip, :struct, required: true
  prop entity, :struct, required: true
  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop payable_id, :string, default: nil

  data check_bank_account_options, :list, default: []
  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{entity: entity, payslip: payslip, payable_id: payable_id} = assigns

    indexed_credit_bank_accounts = bank_accounts_by_owner_name(entity)
    payable = get_payable(payslip, payable_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        payable: payable,
        is_automatic_amount: set_is_automatic_amount(payable),
        selected_method: set_selected_method(payable),
        changeset: set_changeset(payable),
        credit_bank_account_options:
          build_credit_bank_account_options(indexed_credit_bank_accounts),
        selected_credit_bank_account_id: get_primary_account_id(indexed_credit_bank_accounts)
      )
      |> assign_select_options()

    {:ok, socket}
  end

  @impl true
  def handle_event("handle_automatic_amount", _params, socket) do
    {:noreply, update(socket, :is_automatic_amount, &(!&1))}
  end

  @impl true
  def handle_event("select_method", %{"method" => method}, socket) do
    %{assigns: %{changeset: changeset}} = socket

    method = String.to_existing_atom(method)

    socket =
      socket
      |> assign(
        selected_method: method,
        changeset: Finance.set_payable_changeset_method(changeset, method)
      )
      |> assign_select_options()

    {:noreply, socket}
  end

  defp assign_select_options(
         %{assigns: %{selected_method: :check, check_bank_account_options: []}} = socket
       ) do
    check_bank_account_options =
      socket.assigns.registration
      |> company_bank_accounts()
      |> build_check_bank_account_options()

    assign(socket, check_bank_account_options: check_bank_account_options)
  end

  defp assign_select_options(
         %{assigns: %{selected_method: :bank_transfer, credit_bank_account_options: []}} = socket
       ) do
    credit_bank_account_options =
      socket.assigns.registration
      |> company_bank_accounts()
      |> build_credit_bank_account_options()

    assign(socket, credit_bank_account_options: credit_bank_account_options)
  end

  defp assign_select_options(socket), do: socket

  @impl true
  def handle_event("save", %{"payable" => params}, socket) do
    %{params: params, form_state: socket.assigns.form_state, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def handle_event("form_change", %{"payable" => params}, socket) do
    %{form_state: form_state, payable: payable} = socket.assigns

    case form_state do
      :new_mode ->
        {:noreply, assign(socket, changeset: Finance.create_payable_for_payslip_change(params))}

      :edit_mode ->
        {:noreply,
         assign(socket, changeset: Finance.update_payable_for_payslip_change(payable, params))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={handle_title(@form_state)} close={@close_event}>
      <Form for={@changeset} change="form_change" submit="save" opts={autocomplete: "off"}>
        <Field name={:description} class="form-field">
          <Label class="form-label">Descrição</Label>
          <TextInput {...props_for(:description, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:due_date} class="form-field">
          <Label class="form-label">Data</Label>
          <DateInput {...props_for(:due_date, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div :if={@form_state == :new_mode} class="flex justify-start items-center">
          <Switch is_active={@is_automatic_amount} toggle_is_active="handle_automatic_amount"/>
          <label class="form-side-label ml-3":on-click="handle_automatic_amount">Valor Automático</label>
        </div>

        <Field name={:amount} class="form-field">
          <Label class="form-label">
            Valor {if @is_automatic_amount, do: " Automático"}
          </Label>
          <TextInput
            value={format_amount(@changeset)}
            {...props_for(:amount, @form_state, @is_automatic_amount)}
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div class="my-5 flex flex-row justify-between space-x-2 rounded-md">
          <div
            :on-click={unless @form_state == :show_mode, do: "select_method"}
            phx-value-method="bank_transfer"
            class={tab_classes_for(:bank_transfer, @selected_method, @form_state)}
          >
            Transferência
          </div>
          <div
            :on-click={unless @form_state == :show_mode, do: "select_method"}
            phx-value-method="check"
            class={tab_classes_for(:check, @selected_method, @form_state)}
          >
            Cheque
          </div>
          <div
            :on-click={unless @form_state == :show_mode, do: "select_method"}
            phx-value-method="cash"
            class={tab_classes_for(:cash, @selected_method, @form_state)}
          >
            Dinheiro
          </div>
        </div>

        <div :show={@selected_method == :bank_transfer}>
          <Field name={:credit_bank_account_id} class="form-field">
            <Label class="form-label">Conta Bancária</Label>
            <Select
              selected={@selected_credit_bank_account_id}
              options={@credit_bank_account_options}
              {...props_for(:credit_bank_account_id, @form_state)}
            />
            <ErrorTag class="form-error-tag"/>
          </Field>
        </div>

        <div :show={@selected_method == :check}>
          <Field name={:check_number} class="form-field">
            <Label class="form-label">Número do Cheque</Label>
            <TextInput {...props_for(:check_number, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:check_bank_account_id} class="form-field">
            <Label class="form-label">Conta do Cheque</Label>
            <Select
              prompt=""
              options={@check_bank_account_options}
              {...props_for(:check_bank_account_id, @form_state)}
            />
            <ErrorTag class="form-error-tag"/>
          </Field>
        </div>

        <div :if={@message} class="form-error-tag">{@message}</div>

        <div :if={@form_state != :show_mode} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_payable(_payslip, nil), do: nil
  defp get_payable(payslip, payable_id), do: Finance.get_payable_by_payslip(payslip, payable_id)

  defp set_is_automatic_amount(nil), do: false
  defp set_is_automatic_amount(payable), do: payable.payslip_payable.is_auto_adjustable_amount

  defp set_selected_method(nil), do: :bank_transfer
  defp set_selected_method(payable), do: payable.method

  defp set_changeset(nil) do
    Finance.create_payable_for_payslip_change(%{method: :bank_transfer})
  end

  defp set_changeset(payable), do: Finance.update_payable_for_payslip_change(payable)

  defp validate_params(%{form_state: :new_mode} = context) do
    %{payslip: payslip, selected_method: selected_method} = context.socket.assigns

    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("target", :payslip)
      |> Map.put("method", selected_method)
      |> Map.put("reference_date", Date.beginning_of_month(payslip.start_date))
      |> Finance.create_payable_for_payslip_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{payable: payable, selected_method: selected_method} = context.socket.assigns

    params = Map.put(context.params, "method", selected_method)
    changeset = Finance.update_payable_for_payslip_change(payable, params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{payslip: payslip} = context.socket.assigns

    Map.put(
      context,
      :return,
      Finance.create_payable_for_payslip(payslip, changeset.changes,
        is_auto_adjustable_amount: context.socket.assigns.is_automatic_amount
      )
    )
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{payslip: payslip, payable: payable} = context.socket.assigns

    Map.put(
      context,
      :return,
      Finance.update_payable_for_payslip(payslip, payable, changeset.changes)
    )
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, message}} = context) when is_binary(message) do
    {_, changeset} = context.validation

    {:noreply, assign(context.socket, message: message, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}, socket: socket}) when is_struct(changeset) do
    {:noreply, assign(socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _item}, socket: socket}) do
    %{payslip: payslip, form_state: form_state, close_fun: close_fun} = socket.assigns

    Finance.broadcast_payables_for_payslip(payslip)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_flash(:new_mode), do: send(self(), {:flash, :info, "Pagamento adicionado"})
  defp handle_flash(:edit_mode), do: send(self(), {:flash, :info, "Pagamento atualizado"})

  defp bank_accounts_by_owner_name(entity) do
    owned_accounts =
      entity
      |> Finance.list_active_accounts_by_entity()
      |> Enum.map(&{nil, {&1, &1.is_primary}})

    third_party_accounts =
      entity
      |> Finance.list_active_entity_bank_accounts_by_entity_with_holder()
      |> Enum.map(&{Entities.get_name(&1.bank_account.entity), {&1.bank_account, &1.is_primary}})

    owned_accounts ++ third_party_accounts
  end

  defp build_credit_bank_account_options(indexed_accounts) do
    Map.new(indexed_accounts, &build_option/1)
  end

  defp build_option({nil, {account, _}}) do
    option =
      "#{bank_name_with_number(account.routing_number)} - Ag: #{account.branch_number} - Conta: #{account.number}"

    {option, account.id}
  end

  defp build_option({name, {account, _}}) do
    option =
      "#{name}: #{bank_name_with_number(account.routing_number)} - Ag: #{account.branch_number} - Conta: #{account.number}"

    {option, account.id}
  end

  defp build_option(account) do
    option =
      "#{bank_name_with_number(account.routing_number)} - Ag: #{account.branch_number} - Conta: #{account.number}"

    {option, account.id}
  end

  defp get_primary_account_id([]), do: ""

  defp get_primary_account_id(indexed_accounts) do
    {_name, {primary_account, _}} =
      Enum.find(indexed_accounts, fn
        {_name, {_account, true}} -> true
        {_name, {_account, _}} -> false
      end)

    primary_account.id
  end

  defp company_bank_accounts(registration) do
    company = Entities.get_company_by_registration_with_entity(registration)
    owned_accounts = Finance.list_active_accounts_by_entity(company.entity)

    third_party_accounts =
      company.entity
      |> Finance.list_active_entity_bank_accounts_by_entity_with_account()
      |> Enum.map(& &1.bank_account)

    owned_accounts ++ third_party_accounts
  end

  defp build_check_bank_account_options(bank_accounts) do
    Map.new(bank_accounts, &build_option/1)
  end

  defp tab_classes_for(method, method, :show_mode) do
    ~w(bg-gray-100 text-gray-600 font-medium) ++ tab_base_classes()
  end

  defp tab_classes_for(method, method, _form_state) do
    ~w(text-yellow-700 bg-yellow-100 font-medium) ++ tab_base_classes()
  end

  defp tab_classes_for(_method, _active_method, :show_mode) do
    tab_base_classes()
  end

  defp tab_classes_for(_method, _active_method, _form_state) do
    ~w(cursor-pointer hover:bg-gray-100 hover:text-gray-700) ++
      tab_base_classes()
  end

  defp tab_base_classes do
    ~w(w-full py-2 text-gray-500 text-center text-sm rounded-md select-none)
  end

  defp handle_title(:new_mode), do: "Adicionar Valor à Pagar"
  defp handle_title(:edit_mode), do: "Editar Valor à Pagar"
  defp handle_title(:show_mode), do: "Valor à Pagar"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(_field, :show_mode), do: @input_disabled
  defp props_for(_field, _form_state), do: @input_enabled

  defp props_for(:amount, :new_mode, false), do: @input_enabled
  defp props_for(:amount, :edit_mode, false), do: @input_enabled
  defp props_for(:amount, _form_state, _is_automatic_amount), do: @input_disabled
end
