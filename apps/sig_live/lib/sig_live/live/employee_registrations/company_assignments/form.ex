defmodule SigLive.EmployeeRegistrations.CompanyAssignments.Form do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.Entities
  alias Sig.Organizations

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    Select,
    ErrorTag,
    Field,
    Label,
    Submit,
    DateInput
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop org, :struct, required: true
  prop registration, :struct, required: true
  prop company_assignment_id, :string, default: nil

  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{org: org, registration: registration, company_assignment_id: company_assignment_id} =
      assigns

    company_assignment = get_company_assignment(registration, company_assignment_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        companies: Entities.list_companies(org),
        sectors: Organizations.list_org_sectors(org),
        company_assignment: company_assignment,
        changeset: set_changeset(company_assignment)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"company_assignment" => params}, socket) do
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
        <Field name={:assigned_company_id} class="form-field">
          <Label class="form-label">Empresa</Label>
          <Select
            prompt=""
            options={companies_for_select(@companies)}
            {...props_for(:assigned_company_id, @form_state)}
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

        <Field name={:start_date} class="form-field">
          <Label class="form-label">Data de Início</Label>
          <DateInput {...props_for(:start_date, @form_state)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div :if={@message} class="form-error-tag mb-3">{@message}</div>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."} />
        </div>
      </Form>
    </Modal>
    """
  end

  defp handle_title(:new_mode), do: "Nova Designação"
  defp handle_title(:edit_mode), do: "Editar Designação"

  def states, do: @form_states

  defp get_company_assignment(_registration, nil), do: nil

  defp get_company_assignment(registration, company_assignment_id) do
    HR.get_company_assignment(registration, company_assignment_id)
  end

  defp set_changeset(nil), do: HR.create_company_assignment_change()

  defp set_changeset(company_assignment) do
    HR.update_company_assignment_change(company_assignment)
  end

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_company_assignment_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{company_assignment: company_assignment} = context.socket.assigns

    changeset = HR.update_company_assignment_change(company_assignment, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_company_assignment(registration, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{company_assignment: company_assignment} = context.socket.assigns

    Map.put(context, :return, HR.update_company_assignment(company_assignment, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, message}} = context) when is_binary(message) do
    {_, changeset} = context.validation

    {:noreply, assign(context.socket, message: message, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) when is_struct(changeset) do
    {:noreply, assign(context.socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _leave_period}, socket: socket}) do
    %{registration: registration, close_fun: close_fun} = socket.assigns

    HR.broadcast_updated_company_assignments(registration)
    flash_info("Designação atualizada")
    close_fun.()

    {:noreply, socket}
  end

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(_field, _form_state), do: @input_enabled
end
