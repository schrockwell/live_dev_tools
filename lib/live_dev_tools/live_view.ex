defmodule LiveDevTools.LiveView do
  alias LiveDevTools.Events
  alias LiveDevTools.LiveViewSource
  alias LiveDevTools.Messaging
  import Phoenix.LiveView

  defmacro __using__(_) do
    quote do
      on_mount({LiveDevTools.LiveView, __MODULE__})
      @before_compile LiveDevTools.LiveView
    end
  end

  defmacro __before_compile__(_) do
    quote do
      defoverridable render: 1

      def render(assigns) do
        LiveDevTools.LiveView.render_hook(__MODULE__, assigns)
        super(assigns)
      end
    end
  end

  @doc false
  def on_mount(module, params, session, socket) do
    if connected?(socket) do
      socket =
        socket
        |> attach_hook(:live_dev_tools_handle_info, :handle_info, &handle_info_hook(module, &1, &2))
        |> attach_hook(:live_dev_tools_handle_params, :handle_params, &handle_params_hook(module, &1, &2, &3))
        |> attach_hook(:live_dev_tools_handle_event, :handle_event, &handle_event_hook(module, &1, &2, &3))

      Messaging.send_to_dashboards(%Events.Mount{
        params: params,
        session: session,
        source: %LiveViewSource{pid: self(), module: module}
      })

      {:cont, socket}
    else
      {:cont, socket}
    end
  end

  def render_hook(module, assigns) do
    Messaging.send_to_dashboards(%Events.Render{
      assigns: assigns,
      source: %LiveViewSource{pid: self(), module: module}
    })
  end

  def handle_info_hook(module, message, socket) do
    Messaging.send_to_dashboards(%Events.HandleInfo{
      message: message,
      source: %LiveViewSource{pid: self(), module: module}
    })

    {:cont, socket}
  end

  def handle_params_hook(module, params, uri, socket) do
    Messaging.send_to_dashboards(%Events.HandleParams{
      params: params,
      source: %LiveViewSource{pid: self(), module: module},
      uri: uri
    })

    {:cont, socket}
  end

  def handle_event_hook(module, "__dom_components__", %{"components" => components}, socket) do
    components =
      for %{"cid" => cid, "parent_cid" => parent_cid, "dom_id" => dom_id} <- components do
        %{
          cid: cid,
          parent_cid: parent_cid,
          dom_id: dom_id
        }
      end

    Messaging.send_to_dashboards(%Events.DomComponents{
      components: components,
      source: %LiveViewSource{pid: self(), module: module}
    })

    {:halt, socket}
  end

  def handle_event_hook(module, event, params, socket) do
    Messaging.send_to_dashboards(%Events.HandleEvent{
      event: event,
      params: params,
      source: %LiveViewSource{pid: self(), module: module}
    })

    {:cont, socket}
  end
end
