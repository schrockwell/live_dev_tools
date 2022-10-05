defmodule LiveDevTools.Events.HandleEvent do
  defstruct [
    :event,
    :params,
    :pid,
    :source
  ]
end
