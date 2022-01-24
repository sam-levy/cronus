defmodule SigLive.Components.LabelWithError do
  use SigLive, :surface_component

  alias Surface.Components.Form.{ErrorTag, Label}

  slot(default)

  def render(assigns) do
    ~F"""
    <div class="flex">
      <Label class="form-label"><#slot /></Label>
      <ErrorTag class="ml-2 form-error-tag" />
    </div>
    """
  end
end
