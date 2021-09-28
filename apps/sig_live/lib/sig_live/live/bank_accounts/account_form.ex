defmodule SigLive.BankAccounts.AccountForm do
  use SigLive, :surface_live_component

  alias Sig.Finance
  alias Sig.Finance.Banks.Accounts.Account.BankAccountType

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    Checkbox,
    TextInput,
    ErrorTag,
    Field,
    Label,
    Select,
    Submit
  }

  alias SigLive.Components.Modal

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: [:new_mode, :edit_mode, :show_moded, :closed]
  prop entity, :struct, required: true
  prop account_id, :struct, default: nil

  data banks, :map, default: Finance.list_banks()

  @impl true
  def update(assigns, socket) do
    %{entity: entity, account_id: account_id} = assigns
    account = get_account(entity, account_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        account: account,
        changeset: set_changeset(account)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "save",
        %{"account" => account_params},
        %{assigns: %{form_state: :new_mode, entity: entity}} = socket
      ) do
    with {:ok, attrs} <- handle_create_params(account_params),
         {:ok, _account} <- Finance.create_account(entity, attrs) do
      Finance.broadcast_bank_accounts(entity)
      send(self(), {:flash, :info, "Conta adicionada"})
      socket.assigns.close_fun.()

      {:noreply, socket}
    else
      {:error, changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event(
        "save",
        %{"account" => account_params},
        %{assigns: %{form_state: :edit_mode, account: account, entity: entity}} = socket
      ) do
    with {:ok, attrs} <- handle_update_params(account, account_params),
         {:ok, _account} <- Finance.update_account(account, attrs) do
      Finance.broadcast_bank_accounts(entity)
      send(self(), {:flash, :info, "Conta alterada"})
      socket.assigns.close_fun.()

      {:noreply, socket}
    else
      {:error, changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={handle_title(@form_state)} close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:routing_number}>
          <Label class="form-label">Banco</Label>
          <Select options={banks_for_select(@banks)} prompt="" {...props_for(:routing_number, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:branch_number} class="form-field">
          <Label class="form-label">
            Número da Agência
            <span class="form-label-complement">(com dígito)</span>
          </Label>
          <TextInput {...props_for(:branch_number, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:number} class="form-field">
          <Label class="form-label">
            Número da Conta
            <span class="form-label-complement">(com dígito)</span>
          </Label>
          <TextInput {...props_for(:number, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:type} class="form-field">
          <Label class="form-label">Tipo de Conta</Label>
          <Select options={enum_for_select(BankAccountType)} prompt="" {...props_for(:type, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:pix_key} class="form-field">
          <Label class="form-label">Chave PIX</Label>
          <TextInput {...props_for(:pix_key, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:is_primary} class="form-checkbox-field">
          <Checkbox {...props_for_checkbox({:is_primary, @changeset.data}, @form_state)}/>
          <Label class="form-side-label">Conta Principal</Label>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:is_joint_account} class="form-checkbox-field">
          <Checkbox {...props_for_checkbox(:is_joint_account, @form_state)}/>
          <Label class="form-side-label">Conta Conjunta</Label>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:is_active} class="form-checkbox-field">
          <Checkbox {...props_for_checkbox(:is_active, @form_state)}/>
          <Label class="form-side-label">Conta Ativa</Label>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div :if={@form_state != :show_mode} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Adicionando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  defp get_account(_entity, nil), do: nil

  defp get_account(entity, account_id) do
    case Finance.fetch_account(entity, account_id) do
      {:ok, account} -> account
      {:error, :not_found} -> nil
    end
  end

  defp set_changeset(nil), do: Finance.create_account_change(%{})
  defp set_changeset(account), do: Finance.update_account_change(account)

  defp handle_create_params(params) do
    changeset =
      params
      |> Map.put("org_id", "org_id")
      |> Map.put("entity_id", "entity_id")
      |> Finance.create_account_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> {:error, changeset}
      {:ok, _schema} -> {:ok, changeset.changes}
    end
  end

  defp handle_update_params(account, params) do
    changeset = Finance.update_account_change(account, params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> {:error, changeset}
      {:ok, _schema} -> {:ok, changeset.changes}
    end
  end

  defp handle_title(:new_mode), do: "Adicionar Conta Bancária"
  defp handle_title(:edit_mode), do: "Editar Conta Bancária"
  defp handle_title(:show_mode), do: "Conta Bancária"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  @checkbox_enabled [opts: [disabled: false], class: ["form-checkbox"]]
  @checkbox_disabled [opts: [disabled: true], class: ["form-checkbox-disabled"]]

  defp props_for(:pix_key, :show_mode), do: @input_disabled
  defp props_for(:pix_key, _form_state), do: @input_enabled

  defp props_for(_field, :new_mode), do: @input_enabled
  defp props_for(_field, _form_state), do: @input_disabled

  defp props_for_checkbox({:is_primary, _account}, :new_mode), do: @checkbox_enabled
  defp props_for_checkbox({:is_primary, %{is_primary: false}}, :edit_mode), do: @checkbox_enabled
  defp props_for_checkbox({:is_primary, _account}, _form_state), do: @checkbox_disabled

  defp props_for_checkbox(:is_active, :edit_mode), do: @checkbox_enabled
  defp props_for_checkbox(:is_active, _form_state), do: @checkbox_disabled

  defp props_for_checkbox(_field, :new_mode), do: @checkbox_enabled
  defp props_for_checkbox(_field, _form_state), do: @checkbox_disabled
end
