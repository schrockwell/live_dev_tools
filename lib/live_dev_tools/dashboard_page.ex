defmodule LiveDevTools.DashboardPage do
  @moduledoc false

  use Phoenix.LiveDashboard.PageBuilder
  alias Phoenix.LiveDashboard.PageBuilder

  alias LiveDevTools.Events
  alias LiveDevTools.LiveComponentSource
  alias LiveDevTools.LiveViewSource
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
    with %LiveViewSource{pid: pid} <- event.source do
      Process.monitor(pid)
    end

    source = %{
      log: [event],
      parent_cid: nil,
      dom_id: nil
    }

    sources = Map.put(socket.assigns.sources, event.source, source)

    {:noreply, assign(socket, sources: sources)}
  end

  def handle_info(%Events.DomComponents{source: %{pid: pid}, components: components}, socket) do
    updated_sources =
      socket.assigns.sources
      |> Enum.flat_map(fn
        {%LiveComponentSource{pid: ^pid, cid: cid} = source, info} ->
          component = Enum.find(components, &(&1.cid == cid))

          if component do
            # This component info is a known pid and cid, so update it
            [{source, %{info | parent_cid: component.parent_cid, dom_id: component.dom_id}}]
          else
            # The the cid went away, so discard it
            []
          end

        other ->
          # This is a LiveComponent for another pid OR a LiveView, so keep it
          [other]
      end)
      |> Map.new()

    {:noreply, assign(socket, sources: updated_sources)}
  end

  def handle_info(%struct{} = event, socket)
      when struct in [
             Events.HandleEvent,
             Events.HandleInfo,
             Events.HandleParams,
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
    new_sources = Map.reject(socket.assigns.sources, fn {%{pid: key_pid}, _} -> key_pid == pid end)
    {:noreply, assign(socket, :sources, new_sources)}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl PageBuilder
  def handle_event("form-changed", params, socket) do
    IO.inspect(params)
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

  defp append_event(socket, event) do
    new_sources =
      Map.update!(socket.assigns.sources, event.source, fn info ->
        %{info | log: [event | info.log]}
      end)

    assign(socket, :sources, new_sources)
  end

  defp tracked_source?(event, socket) do
    event.source in Map.keys(socket.assigns.sources)
  end
end
