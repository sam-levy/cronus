defmodule SigLive.EmployeeRegistrations.Overtimes.Form do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop registration, :struct, required: true
  prop overtime_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{registration: registration, overtime_id: overtime_id} = assigns

    overtime = get_overtime(registration, overtime_id)
    selected_date = set_selected_date(overtime)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        overtime: overtime,
        changeset: set_changeset(overtime),
        selected_date: selected_date,
        dates_for_select: build_dates_for_select(selected_date, registration.admission_date),
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"overtime" => params}, socket) do
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
        <div class="form-field">
          <label for="overtime_date" class="form-label">Mês</label>

          <select id="overtime_date" name="overtime[date]" class="form-input">
            {#for date <- @dates_for_select}
              <option value={date} selected={date == @selected_date}>
                {format_month(date)}
              </option>
            {/for}
          </select>
        </div>

        <Field name={:hours_amount} class="form-field">
          <Label class="form-label">Horas</Label>
          <TextInput class="form-input"/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div :if={@form_state != :show_mode} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_overtime(_registration, nil), do: nil
  defp get_overtime(registration, overtime_id), do: HR.get_overtime(registration, overtime_id)

  defp set_changeset(nil), do: HR.create_overtime_change()
  defp set_changeset(overtime), do: HR.update_overtime_change(overtime)

  defp set_selected_date(nil), do: Sig.Date.prior_month_start()
  defp set_selected_date(overtime), do: overtime.date

  defp build_dates_for_select(selected_date, floor_date) do
    (Sig.Date.list_by_month(selected_date, :prior, 3) ++
       [selected_date] ++
       Sig.Date.list_by_month(selected_date, :next, 3))
    |> Enum.reject(fn date -> Date.compare(date, floor_date) == :lt end)
  end

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_overtime_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{overtime: overtime} = context.socket.assigns
    changeset = HR.update_overtime_change(overtime, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_overtime(registration, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{overtime: overtime} = context.socket.assigns

    Map.put(context, :return, HR.update_overtime(overtime, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _overtime}, socket: socket}) do
    %{registration: registration, form_state: form_state, close_fun: close_fun} = socket.assigns

    HR.broadcast_registration_overtimes(registration)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_flash(:new_mode), do: flash_info("Hora Extra criada")
  defp handle_flash(:edit_mode), do: flash_info("Hora Extra alterada")

  defp handle_title(:new_mode), do: "Nova Hora Extra"
  defp handle_title(:edit_mode), do: "Editar Hora Extra"
  defp handle_title(:show_mode), do: "Hora Extra"
end
