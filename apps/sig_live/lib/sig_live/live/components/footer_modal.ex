defmodule SigLive.Components.FooterModal do
  use SigLive, :surface_live_component

  prop close, :event, required: true
  prop title, :string

  slot default, required: true
  slot title_content

  data is_collapsed, :boolean, default: false

  @impl true
  def handle_event("toggle_is_collapsed", _, socket) do
    {:noreply, update(socket, :is_collapsed, &(!&1))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div style="padding-bottom: 37rem" class="flex justify-center inset-0 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div class="fixed bottom-0 z-50 flex items-start justify-center pt-4 px-4 text-center">
        <!-- This element is to trick the browser into centering the modal contents. -->
        <span class="hidden inline-block align-middle" aria-hidden="true">&#8203;</span>

        <!-- Modal panel, show/hide based on modal state. -->
        <div class="inline-block align-bottom border bg-white rounded-t-lg text-left overflow-hidden shadow-3xl transform transition-all align-middle w-full">
          <div class="bg-white px-4 py-5">
            <div class="flex items-start">
              <div class="mx-4 text-left w-full">
                <div class="flex justify-between items-center">
                  <h3 class="select-none text-lg leading-6 font-medium text-gray-600" id="modal-title">
                    {#if slot_assigned?(:title_content)}
                      <#slot name="title_content" />
                    {#else}
                      {@title}
                    {/if}
                  </h3>

                  <div class="flex justify-between items-center">
                    <div :on-click="toggle_is_collapsed" class="ml-4 mr-2 p-1 hover:bg-gray-100 hover:rounded-md cursor-pointer text-gray-500">
                      <svg :show={!@is_collapsed} xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>

                      <svg :show={@is_collapsed} xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                      </svg>
                    </div>

                    <div :on-click={@close} class="p-1 hover:bg-gray-100 hover:rounded-md cursor-pointer text-gray-500">
                      <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </div>
                  </div>
                </div>

                <div :show={not @is_collapsed} class="mt-6">
                  <#slot/>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
