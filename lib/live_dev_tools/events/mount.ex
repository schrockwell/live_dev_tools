defmodule LiveDevTools.Events.Mount do
  defstruct [
    :module,
    :params,
    :session,
    :source
  ]
end
