defmodule SigLive.Components.Modal do
  use SigLive, :surface_component

  prop size, :string, default: "small"
  prop close, :event, required: true
  prop title, :string, required: true

  slot default, required: true

  def render(assigns) do
    ~F"""
    <div class="fixed z-10 inset-0 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div class="flex items-start justify-center min-h-screen pt-4 px-4 text-center">
        <!-- Background overlay, show/hide based on modal state. -->
        <div :on-capture-click={@close} class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true"></div>

        <!-- This element is to trick the browser into centering the modal contents. -->
        <span class="hidden inline-block align-middle h-screen" aria-hidden="true">&#8203;</span>

        <!-- Modal panel, show/hide based on modal state. -->
        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all mt-32 align-middle max-w-lg w-full">
          <div class="bg-white px-4 pt-5 pb-4">
            <div class="flex items-start">
              <div class="mx-4 text-left w-full">
                <div class="flex justify-between items-center">
                  <h3 class="text-lg leading-6 font-medium text-gray-600" id="modal-title">
                    {@title}
                  </h3>

                  <div
                    :on-click={@close}
                    class="p-1 hover:bg-gray-100 hover:rounded-md cursor-pointer text-gray-500"
                  >
                    <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </div>
                </div>

                <div class="mt-2">
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
