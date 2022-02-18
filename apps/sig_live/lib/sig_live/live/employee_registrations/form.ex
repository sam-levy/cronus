defmodule SigLive.EmployeeRegistrations.Form do
  use SigLive, :surface_live_component

  alias Sig.Entities
  alias Sig.HR
  alias Sig.Organizations

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    ErrorTag,
    Field,
    Label,
    Select,
    Submit,
    DateInput
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :closed]

  @broadcast_opts [preload: [:registered_at, :sector, :position]]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop org, :struct, required: true
  prop individual, :struct, required: true
  prop registration_id, :string, default: nil

  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{org: org, individual: individual, registration_id: registration_id} = assigns
    registration = get_registration(individual, registration_id)
    companies = Entities.list_companies(org)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        registration: registration,
        changeset: set_changeset(registration),
        companies: companies,
        real_companies: Enum.filter(companies, &(not &1.is_virtual)),
        sectors: Organizations.list_org_sectors(org),
        positions: Organizations.list_org_positions(org)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"registration" => params}, socket) do
    %{params: params, form_state: socket.assigns.form_state, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={handle_title(@form_state)} close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:admission_date}>
          <Label class="form-label">Data de Admissão</Label>
          <DateInput {...props_for(:admission_date, @form_state)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div class="flex space-x-5 form-field">
          <Field name={:number}>
            <Label class="form-label">Número do Registro</Label>
            <TextInput {...props_for(:number, @form_state)}/>
            <ErrorTag class="form-error-tag" />
          </Field>

          <Field name={:e_social_number}>
            <Label class="form-label">Matrícula eSocial</Label>
            <TextInput {...props_for(:number, @form_state)}/>
            <ErrorTag class="form-error-tag" />
          </Field>
        </div>

        <Field name={:salary_amount} :if={@form_state == :new_mode} class="form-field">
          <Label class="form-label">Salário Base</Label>
          <TextInput
            value={format_salary_amount(@changeset)}
            {...props_for(:salary_ammount, @form_state)}
          />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:registered_at_id} class="form-field">
          <Label class="form-label">Empresa de Registro</Label>
          <Select
            prompt=""
            options={companies_for_select(@real_companies)}
            {...props_for(:registered_at_id, @form_state)}
          />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:assigned_company_entity_id} :if={@form_state == :new_mode} class="form-field">
          <Label class="form-label">
            Empresa onde irá trabalhar
            <span class="form-label-complement">(opcional)</span>
          </Label>
          <Select
            prompt=""
            options={companies_for_select(@companies)}
            {...props_for(:assigned_company_entity_id, @form_state)}
          />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:sector_id} class="form-field">
          <Label class="form-label">Setor</Label>
          <Select
            prompt=""
            options={id_by_name_for_select(@sectors)}
            {...props_for(:sector_id, @form_state)}
          />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:position_id} class="form-field">
          <Label class="form-label">Cargo</Label>
          <Select
            prompt=""
            options={id_by_name_for_select(@positions)}
            {...props_for(:position_id, @form_state)}
          />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div :if={@message} class="form-error-tag">{@message}</div>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Adicionando..."} />
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_registration(_individual, nil), do: nil

  defp get_registration(individual, registration_id) do
    HR.get_registration(individual, registration_id)
  end

  defp set_changeset(nil), do: HR.create_registration_change()
  defp set_changeset(registration), do: HR.update_registration_change(registration)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("individual_id", "individual_id")
      |> HR.create_registration_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{registration: registration} = context.socket.assigns

    changeset = HR.update_registration_change(registration, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{org: org, individual: individual} = context.socket.assigns

    case HR.create_registration(org, individual, changeset.changes) do
      {:ok, registration} -> Map.put(context, :return, {:ok, registration})
      {:error, error} -> Map.put(context, :return, {:error, error})
    end
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{registration: registration} = context.socket.assigns

    case HR.update_registration(registration, changeset.changes) do
      {:ok, registration} -> Map.put(context, :return, {:ok, registration})
      {:error, error} -> Map.put(context, :return, {:error, error})
    end
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

  defp handle_return(%{return: {:ok, registration}, socket: socket}) do
    %{individual: individual, form_state: form_state, close_fun: close_fun} = socket.assigns

    handle_broadcast(form_state, individual, registration)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_broadcast(:new_mode, individual, registration) do
    HR.broadcast_new_individual_registration(individual, registration, @broadcast_opts)
  end

  defp handle_broadcast(:edit_mode, individual, registration) do
    HR.broadcast_updated_individual_registration(individual, registration, @broadcast_opts)
  end

  defp handle_flash(:new_mode), do: flash_info("Registro criado")
  defp handle_flash(:edit_mode), do: flash_info("Registro atualizado")

  defp handle_title(:new_mode), do: "Adicionar Registro de Trabalho"
  defp handle_title(:edit_mode), do: "Editar Registro de Trabalho"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(_field, :new_mode), do: @input_enabled

  defp props_for(:salary_ammount, :edit_mode), do: @input_disabled
  defp props_for(:assigned_company_entity_id, :edit_mode), do: @input_disabled

  defp props_for(_field, :edit_mode), do: @input_enabled

  defp format_salary_amount(%{changes: %{salary_amount: amount}}), do: format_amount(amount)
  defp format_salary_amount(_), do: ""
end
