defmodule LiveDevTools.Guards do
  defguard is_live_view(source) when is_atom(source)
  defguard is_live_component(source) when is_tuple(source) and is_atom(elem(source, 0))
end
