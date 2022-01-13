defmodule SigLive do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use SigLive, :controller
      use SigLive, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  defmodule LiveView.Callbacks do
    defmacro __using__(_) do
      quote do
        def handle_info({:flash, type, message}, socket) do
          Process.send_after(self(), :clear_flash, 2000)

          {:noreply, put_flash(socket, type, message)}
        end

        def handle_info(:clear_flash, socket), do: {:noreply, clear_flash(socket)}
      end
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: SigLive

      import Plug.Conn
      import SigLive.Gettext
      alias SigLive.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/sig_live/templates",
        namespace: SigLive

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {SigLive.LayoutView, "live.html"}

      use SigLive.LiveView.Callbacks

      unquote(view_helpers())
      unquote(live_view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
      unquote(live_view_helpers())
    end
  end

  def surface_live_view do
    quote do
      use Surface.LiveView,
        layout: {SigLive.LayoutView, "live.html"}

      use SigLive.LiveView.Callbacks

      unquote(view_helpers())
      unquote(live_view_helpers())
    end
  end

  def surface_component do
    quote do
      use Surface.Component

      unquote(view_helpers())
      unquote(live_view_helpers())
    end
  end

  def surface_live_component do
    quote do
      use Surface.LiveComponent

      unquote(view_helpers())
      unquote(live_view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import SigLive.Gettext
    end
  end

  defp live_view_helpers do
    quote do
      import Ecto.Changeset, only: [apply_action: 2]

      # Import custom LiveView helpers
      import SigLive.LiveViewHelpers

      alias Ecto.UUID
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Ecto, only: [assoc_loaded?: 1]

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      # Import custom view helpers
      import SigLive.ViewHelpers

      import SigLive.ErrorHelpers
      import SigLive.Gettext

      alias SigLive.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
