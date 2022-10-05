defmodule LiveDevTools.DashboardPage do
  @moduledoc false

  use Phoenix.LiveDashboard.PageBuilder
  alias Phoenix.LiveDashboard.PageBuilder

  import LiveDevTools.Guards
  alias LiveDevTools.Events
  alias LiveDevTools.Messaging

  @impl PageBuilder
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Messaging.register_dashboard()
    end

    socket = assign(socket, sources: %{})

    {:ok, socket}
  end

  @impl PageBuilder
  def handle_info(%Events.Mount{} = event, socket) do
    if is_live_view(event.source) do
      Process.monitor(event.pid)
    end

    source = %{
      id: event.pid,
      log: [event]
    }

    sources = Map.put(socket.assigns.sources, source_key(event), source)

    {:noreply, assign(socket, sources: sources)}
  end

  def handle_info(%Events.Render{pid: pid} = event, socket) do
    if tracked_source?(event, socket) do
      # DANGER: phoenix_live_view internal implementation details - should version-control this
      # or figure out another way!
      %{components: components} = :sys.get_state(event.pid)
      cids = Map.keys(elem(components, 0))

      # Reject all cids that are no longer relevant
      filtered_sources =
        Map.filter(socket.assigns.sources, fn
          {{^pid, {_module, %{cid: cid}}}, _} -> cid in cids
          _ -> true
        end)

      {:noreply,
       socket
       |> assign(:sources, filtered_sources)
       |> append_event(event)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%struct{} = event, socket)
      when struct in [
             Events.HandleEvent,
             Events.HandleInfo,
             Events.HandleParams,
             Events.Mount,
             Events.Render,
             Events.Update
           ] do
    if tracked_source?(event, socket) do
      {:noreply, append_event(socket, event)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket) do
    new_sources = Map.reject(socket.assigns.sources, fn {{key_pid, _}, _} -> key_pid == pid end)
    {:noreply, assign(socket, :sources, new_sources)}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl PageBuilder
  def menu_link(_, _) do
    {:ok, "DevTools"}
  end

  @impl PageBuilder
  def render_page(assigns) do
    {LiveDevTools.Dashboard, %{id: "live-dev-tools-dashboard", sources: assigns.sources}}
  end

  defp source_key(event) do
    {event.pid, event.source}
  end

  defp append_event(socket, event) do
    new_sources =
      Map.update!(socket.assigns.sources, source_key(event), fn info ->
        %{info | log: [event | info.log]}
      end)

    assign(socket, :sources, new_sources)
  end

  defp tracked_source?(event, socket) do
    source_key(event) in Map.keys(socket.assigns.sources)
  end
end
