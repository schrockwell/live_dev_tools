defmodule LiveDevTools.DashboardPage do
  @moduledoc false

  use Phoenix.LiveDashboard.PageBuilder
  alias Phoenix.LiveDashboard.PageBuilder

  alias LiveDevTools.Events
  alias LiveDevTools.Messaging

  @impl PageBuilder
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Messaging.register_dashboard()
    end

    socket = assign(socket, views: [])

    {:ok, socket}
  end

  @impl PageBuilder
  def handle_info(%Events.Mount{} = event, socket) do
    # New LiveView to watch!
    if event.source.cid == nil do
      Process.monitor(event.source.pid)
    end

    view = %{
      id: event.source.id,
      cid: event.source.cid,
      dom_id: nil,
      log: [event],
      module: event.module,
      parent_cid: nil,
      pid: event.source.pid
    }

    {:noreply, assign(socket, views: [view | socket.assigns.views])}
  end

  def handle_info(%Events.DomComponents{source: %{pid: pid}, components: components}, socket) do
    updated_views =
      Enum.flat_map(socket.assigns.views, fn
        %{cid: nil} = view ->
          # LiveView, so keep it
          [view]

        %{pid: ^pid} = view ->
          if component = Enum.find(components, &(&1.cid == view.cid)) do
            # This component info is a known pid and cid, so update it
            [%{view | parent_cid: component.parent_cid, dom_id: component.dom_id}]
          else
            # The the cid went away, so discard it
            []
          end

        other ->
          # This is a LiveComponent for another pid, so leave it
          [other]
      end)

    {:noreply, assign(socket, views: updated_views)}
  end

  def handle_info(%struct{} = event, socket)
      when struct in [
             Events.HandleEvent,
             Events.HandleInfo,
             Events.HandleParams,
             Events.Render,
             Events.Update
           ] do
    {:noreply, socket}
    # {:noreply, append_event(socket, event)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket) do
    new_views = Enum.reject(socket.assigns.views, fn %{pid: view_pid} -> view_pid == pid end)
    {:noreply, assign(socket, :views, new_views)}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl PageBuilder
  def handle_event("change", params, socket) do
    IO.inspect(params, label: "change")
    {:noreply, socket}
  end

  @impl PageBuilder
  def menu_link(_, _) do
    {:ok, "DevTools"}
  end

  @impl PageBuilder
  def render_page(assigns) do
    {LiveDevTools.Dashboard, %{id: "live-dev-tools-dashboard", views: assigns.views}}
  end

  defp append_event(socket, event) do
    %{pid: event_pid, cid: event_cid} = event.source

    new_views =
      Enum.map(socket.assigns.views, fn
        %{pid: ^event_pid, cid: ^event_cid} = view -> %{view | log: [event | view.log]}
        view -> view
      end)

    assign(socket, :views, new_views)
  end

  # defp tracked_view?(event, socket) do
  #   Enum.any?(socket.assigns.views, fn view -> Map.take(view, [:pid, :cid]) == event.source end)
  # end
end
