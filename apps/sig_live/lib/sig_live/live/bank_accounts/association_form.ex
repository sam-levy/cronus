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
  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :show_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
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
        accounts: maybe_set_account_for_select(entity_bank_account),
        entities_relationships:
          maybe_set_entities_relationships_for_select(entity, entity_bank_account)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("fetch_entity_by_document", params, socket) do
    %{"fetch_entity" => %{"document" => document}} = params
    %{org: org} = socket.assigns

    case Entities.fetch_by_document(org, document) do
      {:ok, account_holder_entity} ->
        handle_account_holder_entity_found(account_holder_entity, document, socket)

      {:error, :not_found} ->
        {:noreply,
         assign(socket, changeset: nil, document: document, message: "Pessoa não cadastrada.")}

      :error ->
        {:noreply,
         assign(socket, changeset: nil, document: document, message: "Documento inválido.")}
    end
  end

  @impl true
  def handle_event("save", %{"entity_bank_account" => params}, socket) do
    %{params: params, form_state: socket.assigns.form_state, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def handle_event("clear", _params, socket) do
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
            <Select
              prompt=""
              options={bank_accounts_for_select(@accounts)}
              {...props_for(:bank_account_id, @form_state)}
            />
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:relationship_with_holder} class="form-field">
            <Label class="form-label">Relação com o Titular</Label>
            <Select
              prompt=""
              options={@entities_relationships}
              {...props_for(:relationship_with_holder, @form_state)}
            />
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

          <div :if={@message} class="form-error-tag">{@message}</div>

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
            <Select
              options={@entities_relationships}
              {...props_for(:relationship_with_holder, @form_state)}
            />
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:is_joint_account_holder} class="form-checkbox-field">
            <Checkbox {...props_for_checkbox(:is_joint_account_holder, @form_state)}/>
            <Label class="form-side-label">Titular da Conta Conjunta</Label>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:routing_number}>
            <Label class="form-label">Banco</Label>
            <Select
              selected={@changeset.data.bank_account.routing_number}
              options={bank_for_select(@changeset.data.bank_account.routing_number)}
              {...props_for(:routing_number, @form_state)}
            />
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
            <Select
              selected={@changeset.data.bank_account.type}
              options={enum_for_select(BankAccountType)}
              {...props_for(:type, @form_state)}
            />
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

  def states, do: @form_states

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

  defp maybe_set_entities_relationships_for_select(_entity, nil = _eba), do: %{}

  defp maybe_set_entities_relationships_for_select(entity, eba) do
    entities_relationships_for_select(entity, eba.bank_account.entity)
  end

  def entities_relationships_for_select(entity, holder_entity) do
    holder_entity
    |> Finance.entities_relationships(entity)
    |> Map.new(&{&1, &1})
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
    %{entity: entity} = socket.assigns

    case Finance.list_accounts_by(account_holder_entity, where: [is_active: true]) do
      [] ->
        message = "#{name} não possui contas bancárias ativas."
        {:noreply, assign(socket, document: document, message: message)}

      accounts ->
        {:noreply,
         assign(socket,
           changeset: Finance.create_entity_bank_account_change(%{}),
           account_holder_name: name,
           entities_relationships:
             entities_relationships_for_select(account_holder_entity, entity),
           document: document,
           accounts: accounts,
           message: nil
         )}
    end
  end

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("entity_id", "entity_id")
      |> Finance.create_entity_bank_account_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{entity_bank_account: eba} = context.socket.assigns

    changeset = Finance.update_entity_bank_account_change(eba, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{entity: entity} = context.socket.assigns

    case Finance.create_entity_bank_account(entity, changeset.changes) do
      {:ok, eba} -> Map.put(context, :return, {:ok, eba})
      {:error, error} -> Map.put(context, :return, {:error, error})
    end
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{entity_bank_account: eba} = context.socket.assigns

    case Finance.update_entity_bank_account(eba, changeset.changes) do
      {:ok, eba} -> Map.put(context, :return, {:ok, eba})
      {:error, error} -> Map.put(context, :error, error)
    end
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, message}, socket: socket} = context)
       when is_binary(message) do
    {_, changeset} = context.validation

    {:noreply, assign(socket, message: message, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}, socket: socket}) when is_struct(changeset) do
    {:noreply, assign(socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _eba}, socket: socket}) do
    %{entity: entity, form_state: form_state, close_fun: close_fun} = socket.assigns

    Finance.broadcast_accounts_and_relations(entity)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_flash(:new_mode), do: send(self(), {:flash, :info, "Associação criada"})
  defp handle_flash(:edit_mode), do: send(self(), {:flash, :info, "Associação atualizada"})

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
