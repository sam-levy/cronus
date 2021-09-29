defmodule SigLive.BankAccounts.AssociationForm do
  use SigLive, :surface_live_component

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

  alias Sig.Entities
  alias Sig.Finance
  alias Sig.Finance.Banks.Accounts.Account.BankAccountType
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount.RelationshipWithHolder
  alias SigLive.Components.Modal

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: [:new_mode, :edit_mode, :show_moded, :closed]
  prop org, :struct, required: true
  prop entity, :struct, required: true
  prop account_id, :string, default: nil

  data document, :string, default: nil
  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{entity: entity, account_id: account_id} = assigns
    entity_bank_account = get_eba(entity, account_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        entity_bank_account: entity_bank_account,
        changeset: maybe_set_changeset(entity_bank_account),
        account_holder_name: maybe_set_account_holder_name(entity_bank_account),
        accounts: maybe_set_account_for_select(entity_bank_account)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "fetch_entity_by_document",
        %{"fetch_entity" => %{"document" => document}},
        socket
      ) do
    %{org: org} = socket.assigns

    case Entities.fetch_by_document(org, document) do
      {:ok, account_holder_entity} ->
        handle_account_holder_entity_found(account_holder_entity, document, socket)

      {:error, :not_found} ->
        {:noreply,
         assign(socket, changeset: nil, document: document, message: "Pessoa não cadastrada")}

      :error ->
        {:noreply,
         assign(socket, changeset: nil, document: document, message: "Documento inválido")}
    end
  end

  @impl true
  def handle_event(
        "save",
        %{"entity_bank_account" => eba_params},
        %{assigns: %{form_state: :new_mode, entity: entity}} = socket
      ) do
    with {:ok, attrs} <- handle_create_params(eba_params),
         {:ok, _account} <- Finance.create_entity_bank_account(entity, attrs) do
      Finance.broadcast_accounts_and_relations(entity)
      send(self(), {:flash, :info, "Associação criada"})
      socket.assigns.close_fun.()

      {:noreply, socket}
    else
      {:error, changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event(
        "save",
        %{"entity_bank_account" => eba_params},
        %{assigns: %{form_state: :edit_mode, entity_bank_account: eba, entity: entity}} = socket
      ) do
    with {:ok, attrs} <- handle_update_params(eba, eba_params),
         {:ok, _account} <- Finance.update_entity_bank_account(eba, attrs) do
      Finance.broadcast_accounts_and_relations(entity)
      send(self(), {:flash, :info, "Associação alterada"})
      socket.assigns.close_fun.()

      {:noreply, socket}
    else
      {:error, changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("clear", _, socket) do
    {:noreply, assign(socket, document: nil, message: nil)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={handle_title(@form_state)} close={@close_event}>
      {#if is_nil(@changeset)}

        <Form for={:fetch_entity} submit="fetch_entity_by_document" opts={autocomplete: "off"}>
          <Field name={:document} class="form-field">
            <Label class="form-label">
              Documento do Titular da Conta
              <span class="form-label-complement">(CPF ou CNPJ)</span>
            </Label>

            <TextInput value={format_document(@document)} class="form-input" opts={autofocus: true}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <blockquote :if={@message} class="text-gray-500 text-sm">
            <em>{@message}</em>
          </blockquote>

          <div class="mt-5 flex justify-between">
            <div class="self-center">
              <a :show={@message} :on-click="clear" class="cursor-pointer text-blue-600 text-sm font-medium">Limpar</a>
            </div>

            <Submit class="btn-blue" label="Buscar" opts={phx_disable_with: "Buscando..."}/>
          </div>
        </Form>

      {#elseif @changeset && @form_state == :new_mode}

        <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
          <Field name={:account_holder_name} class="form-field">
            <Label class="form-label">Titular da Conta</Label>
            <TextInput value={@account_holder_name} {...props_for(:account_holder_name, @form_state)}/>
          </Field>

          <Field name={:bank_account_id} class="form-field">
            <Label class="form-label">Conta Bancária</Label>
            <Select options={bank_accounts_for_select(@accounts)} prompt="" {...props_for(:bank_account_id, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:relationship_with_holder} class="form-field">
            <Label class="form-label">Relação com o Titular</Label>
            <Select options={enum_for_select(RelationshipWithHolder)} prompt="" {...props_for(:relationship_with_holder, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:is_primary} class="form-checkbox-field">
            <Checkbox {...props_for_checkbox({:is_primary, @changeset.data}, @form_state)}/>
            <Label class="form-side-label">Conta Principal</Label>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:is_joint_account_holder} class="form-checkbox-field">
            <Checkbox {...props_for_checkbox(:is_joint_account_holder, @form_state)}/>
            <Label class="form-side-label">Titular da Conta Conjunta</Label>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <div class="flex justify-end">
            <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Adicionando..."}/>
          </div>
        </Form>

      {#else}

        <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
          <Field name={:account_holder_name} class="form-field">
            <Label class="form-label">Titular da Conta</Label>
            <TextInput value={@account_holder_name} {...props_for(:account_holder_name, @form_state)}/>
          </Field>

          <Field name={:relationship_with_holder} class="form-field">
            <Label class="form-label">Relação com o Titular</Label>
            <Select options={enum_for_select(RelationshipWithHolder)} prompt="" {...props_for(:relationship_with_holder, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:is_joint_account_holder} class="form-checkbox-field">
            <Checkbox {...props_for_checkbox(:is_joint_account_holder, @form_state)}/>
            <Label class="form-side-label">Titular da Conta Conjunta</Label>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:routing_number}>
            <Label class="form-label">Banco</Label>
            <Select selected={@changeset.data.bank_account.routing_number} options={bank_for_select(@changeset.data.bank_account.routing_number)} {...props_for(:routing_number, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:branch_number} class="form-field">
            <Label class="form-label">
              Número da Agência
              <span class="form-label-complement">(com dígito)</span>
            </Label>
            <TextInput value={@changeset.data.bank_account.branch_number} {...props_for(:branch_number, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:number} class="form-field">
            <Label class="form-label">
              Número da Conta
              <span class="form-label-complement">(com dígito)</span>
            </Label>
            <TextInput value={@changeset.data.bank_account.number} {...props_for(:number, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:type} class="form-field">
            <Label class="form-label">Tipo de Conta</Label>
            <Select selected={@changeset.data.bank_account.type} options={enum_for_select(BankAccountType)} prompt="" {...props_for(:type, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:pix_key} class="form-field">
            <Label class="form-label">Chave PIX</Label>
            <TextInput value={@changeset.data.bank_account.pix_key} {...props_for(:pix_key, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:is_primary} class="form-checkbox-field">
            <Checkbox {...props_for_checkbox({:is_primary, @changeset.data}, @form_state)}/>
            <Label class="form-side-label">Conta Principal</Label>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <div :if={@form_state != :show_mode} class="flex justify-end">
            <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Adicionando..."}/>
          </div>
        </Form>

      {/if}
    </Modal>
    """
  end

  defp get_eba(_entity, nil), do: nil

  defp get_eba(entity, account_id) do
    Finance.get_entity_bank_account_with_holder(entity, account_id)
  end

  defp maybe_set_changeset(nil), do: nil
  defp maybe_set_changeset(eba), do: Finance.update_entity_bank_account_change(eba)

  defp maybe_set_account_holder_name(nil), do: ""
  defp maybe_set_account_holder_name(eba), do: Entities.get_name(eba.bank_account.entity)

  defp maybe_set_account_for_select(nil), do: nil
  defp maybe_set_account_for_select(eba), do: [eba.bank_account]

  defp handle_create_params(params) do
    changeset =
      params
      |> Map.put("org_id", "org_id")
      |> Map.put("entity_id", "entity_id")
      |> Finance.create_entity_bank_account_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> {:error, changeset}
      {:ok, _schema} -> {:ok, changeset.changes}
    end
  end

  defp handle_update_params(eba, params) do
    changeset = Finance.update_entity_bank_account_change(eba, params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> {:error, changeset}
      {:ok, _schema} -> {:ok, changeset.changes}
    end
  end

  defp handle_account_holder_entity_found(account_holder_entity, document, socket) do
    name = Entities.get_name(account_holder_entity)

    if socket.assigns.entity.id == account_holder_entity.id do
      message =
        "#{name} é a pessoa atual. Insira uma conta bancária própria para esta pessoa ou busque por outra."

      {:noreply, assign(socket, document: document, message: message)}
    else
      handle_list_accounts(account_holder_entity, name, document, socket)
    end
  end

  defp handle_list_accounts(account_holder_entity, name, document, socket) do
    case Finance.list_active_accounts_by_entity(account_holder_entity) do
      [] ->
        message = "#{name} não possui contas bancárias ativas."
        {:noreply, assign(socket, document: document, message: message)}

      accounts ->
        {:noreply,
         assign(socket,
           changeset: Finance.create_entity_bank_account_change(%{}),
           account_holder_name: name,
           document: document,
           accounts: accounts,
           message: nil
         )}
    end
  end

  defp handle_title(:new_mode), do: "Associar Conta Bancária de Outro Titular"
  defp handle_title(:edit_mode), do: "Editar Associação"
  defp handle_title(:show_mode), do: "Conta Bancária Asssociada"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  @checkbox_enabled [opts: [disabled: false], class: ["form-checkbox"]]
  @checkbox_disabled [opts: [disabled: true], class: ["form-checkbox-disabled"]]

  defp props_for(:account_holder_name, _form_state), do: @input_disabled
  defp props_for(:routing_number, _form_state), do: @input_disabled
  defp props_for(:branch_number, _form_state), do: @input_disabled
  defp props_for(:number, _form_state), do: @input_disabled
  defp props_for(:type, _form_state), do: @input_disabled
  defp props_for(:pix_key, _form_state), do: @input_disabled

  defp props_for(_field, :new_mode), do: @input_enabled
  defp props_for(_field, _form_state), do: @input_disabled

  defp props_for_checkbox({:is_primary, _account}, :new_mode), do: @checkbox_enabled
  defp props_for_checkbox({:is_primary, %{is_primary: false}}, :edit_mode), do: @checkbox_enabled
  defp props_for_checkbox({:is_primary, _account}, _form_state), do: @checkbox_disabled

  defp props_for_checkbox(_field, :new_mode), do: @checkbox_enabled
  defp props_for_checkbox(_field, _form_state), do: @checkbox_disabled
end
