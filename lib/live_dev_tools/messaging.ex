defmodule LiveDevTools.Messaging do
  @registry LiveDevTools.Registry

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {Registry, :start_link, [[keys: :duplicate, name: @registry]]}
    }
  end

  def register_dashboard do
    Registry.register(@registry, :dashboard, nil)
    :ok
  end

  def send_to_dashboards(message) do
    Registry.dispatch(@registry, :dashboard, fn entries ->
      for {pid, _} <- entries, do: send(pid, message)
    end)
  end

  :ok
end
