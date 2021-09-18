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
  prop org_id, :string, required: true

  data gender_options, :map, default: Gender.__enums__
  data cpf, :string, default: nil
  data changeset, :struct, default: nil
  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("fetch_individual_by_cpf", %{"validate_cpf" => %{"cpf" => cpf}}, socket) do
    case Entities.fetch_individual_by_cpf(socket.assigns.org_id, cpf) do
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
    org_id = socket.assigns.org_id
    attrs = Entities.cast_individual_params(individual_params)

    case Entities.create_individual(org_id, attrs) do
      {:ok, _individual} ->
        Entities.broadcast_individuals(org_id)
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
          <Field name={:cpf} class={field_class()}>
            <Label class={label_class()}>CPF</Label>
            <TextInput class={text_input_class()} opts={autofocus: true}/>
            <ErrorTag class={error_tag_class()}/>
          </Field>

          <blockquote :if={@message} class="text-gray-500 text-sm">
            <em>{@message}</em>
          </blockquote>

          <div class="mt-5 flex justify-end">
            <Submit class={submit_class()} label="Validar" phx-disable-with="Validando..."/>
          </div>
        </Form>

      {#else}

        <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
          <Field name={:cpf} class={field_class()}>
            <Label class={label_class()}>CPF</Label>
            <TextInput class={text_input_class()} value={format_cpf_in_changeset(@changeset)} opts={readonly: true}/>
            <ErrorTag class="error"/>
          </Field>

          <Field name={:name} class={field_class()}>
            <Label class={label_class()}>Nome</Label>
            <TextInput class={text_input_class()} opts={autofocus: true}/>
            <ErrorTag class={error_tag_class()}/>
          </Field>

          <Field name={:gender}>
            <Label class={label_class()}>Sexo</Label>
            <Select class={text_input_class()} options={@gender_options} prompt=""/>
            <ErrorTag class="error"/>
          </Field>

          <div class="mt-5 flex justify-end">
            <Submit class={submit_class()} label="Salvar" phx-disable-with="Salvando..."/>
          </div>
        </Form>

      {/if}
    </Modal>
    """
  end

  defp field_class do
    "my-5"
  end

  defp label_class do
    "block text-sm font-medium text-gray-600 mb-1"
  end

  defp text_input_class() do
    "block w-full shadow-sm text-sm border border-gray-300 rounded-md"
  end

  defp error_tag_class() do
    "text-red text-xs italic"
  end

  defp submit_class() do
    "hover:bg-blue-200 hover:text-blue-800 group flex items-center rounded-md bg-blue-100 text-blue-600 text-sm font-medium px-4 py-2"
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
