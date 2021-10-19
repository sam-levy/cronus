defmodule SigLive.EmployeeRegistrations.Salaries.Form do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    ErrorTag,
    Field,
    Label,
    Submit,
    DateInput
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop registration, :struct, required: true

  data changeset, :struct, default: HR.create_salary_change()
  data message, :string, default: nil

  @impl true
  def handle_event("save", %{"salary" => params}, socket) do
    %{params: params, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
      <Modal title="Atualizar Salário" close={@close_event}>
        <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
          <Field name={:start_date}>
            <Label class="form-label">Data de Início</Label>
            <DateInput class="form-input"/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:amount} class="form-field">
            <Label class="form-label">Valor</Label>
            <TextInput class="form-input" value={format_salary_amount(@changeset)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <div :if={@message} class="form-error-tag mb-3">{@message}</div>

          <div class="flex justify-end">
            <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Atualizando..."}/>
          </div>
        </Form>
      </Modal>
    """
  end

  def states, do: @form_states

  defp validate_params(context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_salary_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_salary(registration, changeset.changes))
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

  defp handle_return(%{return: {:ok, _salary}, socket: socket}) do
    %{registration: registration, close_fun: close_fun} = socket.assigns

    HR.broadcast_registration_salaries(registration)
    HR.broadcast_registration_recurring_payslip_items(registration)

    send(self(), {:flash, :info, "Salário Atualizado"})
    close_fun.()

    {:noreply, socket}
  end

  defp format_salary_amount(%{changes: %{amount: amount}}), do: format_amount(amount)
  defp format_salary_amount(_), do: ""
end
