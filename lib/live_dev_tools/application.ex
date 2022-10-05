defmodule LiveDevTools.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [LiveDevTools.Messaging]
    opts = [strategy: :one_for_one, name: LiveDevTools.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
