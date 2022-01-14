defmodule SigLive.LiveViewHelpers do
  def flash_info(message) when is_binary(message) do
    send(self(), {:flash, :info, message})
  end

  def flash_error(message) when is_binary(message) or is_atom(message) do
    send(self(), {:flash, :error, message})
  end
end
