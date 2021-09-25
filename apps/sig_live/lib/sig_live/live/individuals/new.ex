defmodule SigLive.Individuals.New do
  use SigLive, :surface_live_component

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    ErrorTag,
    Field,
    Label,
    Select,
    Submit
  }

  alias Sig.Entities
  alias Sig.Entities.Individuals.Individual.Gender

  alias SigLive.Components.Modal

  prop close, :event, required: true
  prop org, :struct, required: true

  data gender_options, :map, default: Gender.__enums__()
  data cpf, :string, default: nil
  data changeset, :struct, default: nil
  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("fetch_individual_by_cpf", %{"validate_cpf" => %{"cpf" => cpf}}, socket) do
    case Entities.fetch_individual_by_cpf(socket.assigns.org, cpf) do
      {:ok, individual} ->
        handle_found_individual(individual, socket)

      {:error, :not_found} ->
        handle_new_individual(cpf, socket)

      {:error, message} ->
        {:noreply, assign(socket, changeset: nil, cpf: cpf, message: message)}
    end
  end

  @impl true
  def handle_event("save", %{"individual" => individual_params}, socket) do
    org = socket.assigns.org
    attrs = Entities.cast_individual_params(individual_params)

    case Entities.create_individual(org, attrs) do
      {:ok, _individual} ->
        Entities.broadcast_individuals(org)
        send(self(), "individual_created")
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Adicionar Pessoa" {=@close}>
      {#if is_nil(@changeset)}

        <Form for={:validate_cpf} submit="fetch_individual_by_cpf" opts={autocomplete: "off"}>
          <Field name={:cpf} class="form-field">
            <Label class="form-label">CPF</Label>
            <TextInput class="form-input" opts={autofocus: true}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <blockquote :if={@message} class="text-gray-500 text-sm">
            <em>{@message}</em>
          </blockquote>

          <div class="mt-5 flex justify-end">
            <Submit class="btn-blue" label="Validar" opts={[phx_disable_with: "Validando..."]}/>
          </div>
        </Form>

      {#else}

        <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
          <Field name={:cpf} class="form-field">
            <Label class="form-label">CPF</Label>
            <TextInput class="form-input" value={format_cpf_in_changeset(@changeset)} opts={readonly: true}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:name} class="form-field">
            <Label class="form-label">Nome</Label>
            <TextInput class="form-input" opts={autofocus: true}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:gender}>
            <Label class="form-label">Sexo</Label>
            <Select class="form-input" options={@gender_options} prompt=""/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <div class="mt-5 flex justify-end">
            <Submit class="btn-blue" label="Salvar" opts={[phx_disable_with: "Adicionando..."]}/>
          </div>
        </Form>

      {/if}
    </Modal>
    """
  end

  defp format_cpf_in_changeset(%{changes: %{cpf: cpf}}) do
    format_cpf(cpf)
  end

  defp handle_found_individual(individual, socket) do
    message = individual.name <> " já existe no cadastro"

    {:noreply, assign(socket, changeset: nil, cpf: individual.cpf, message: message)}
  end

  defp handle_new_individual(cpf, socket) do
    changeset = Entities.individual_change(%{"cpf" => cpf})

    {:noreply, assign(socket, changeset: changeset, message: nil)}
  end
end
