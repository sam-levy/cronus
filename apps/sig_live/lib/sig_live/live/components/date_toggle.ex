  defmodule SigLive.Components.DateToggle do
    use SigLive, :surface_component

    alias Surface.Components.Form
    alias Surface.Components.Form.DateInput
    alias Surface.Components.Form.Field

    prop start_date, :date, required: true
    prop end_date, :date, required: true
    prop handle_period, :event
    prop next, :event
    prop previous, :event

    @impl true
    def render(assigns) do
      ~F"""
      <div class="flex items-center text-gray-500 font-medium text-sm tracking-wider rounded-md">
        <button :on-click={@previous}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M15.707 15.707a1 1 0 01-1.414 0l-5-5a1 1 0 010-1.414l5-5a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 010 1.414zm-6 0a1 1 0 01-1.414 0l-5-5a1 1 0 010-1.414l5-5a1 1 0 011.414 1.414L5.414 10l4.293 4.293a1 1 0 010 1.414z" clip-rule="evenodd" />
          </svg>
        </button>

        <Form for={:toggle_date} change={@handle_period} opts={autocomplete: "off"} class="flex">
          <Field name={:start_date}>
            <DateInput class="form-input-transparent p-1 pl-4" value={@start_date} opts={required: true}/>
          </Field>

          <Field name={:end_date}>
            <DateInput class="form-input-transparent p-1 pl-0" value={@end_date} opts={required: true}/>
          </Field>
        </Form>

        <button :on-click={@next}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10.293 15.707a1 1 0 010-1.414L14.586 10l-4.293-4.293a1 1 0 111.414-1.414l5 5a1 1 0 010 1.414l-5 5a1 1 0 01-1.414 0z" clip-rule="evenodd" />
            <path fill-rule="evenodd" d="M4.293 15.707a1 1 0 010-1.414L8.586 10 4.293 5.707a1 1 0 011.414-1.414l5 5a1 1 0 010 1.414l-5 5a1 1 0 01-1.414 0z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
      """
    end
  end
