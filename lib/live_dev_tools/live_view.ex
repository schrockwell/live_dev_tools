defmodule LiveDevTools.LiveView do
  alias LiveDevTools.Events
  alias LiveDevTools.Messaging
  alias LiveDevTools.Util
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
      id = Util.random_id()

      socket =
        socket
        |> attach_hook(:live_dev_tools_handle_info, :handle_info, &handle_info_hook(module, &1, &2))
        |> attach_hook(:live_dev_tools_handle_params, :handle_params, &handle_params_hook(module, &1, &2, &3))
        |> attach_hook(:live_dev_tools_handle_event, :handle_event, &handle_event_hook(module, &1, &2, &3))
        |> Util.put_id(id)

      Messaging.send_to_dashboards(%Events.Mount{
        module: module,
        params: params,
        session: session,
        source: %{pid: self(), cid: nil, id: id}
      })

      {:cont, socket}
    else
      {:cont, socket}
    end
  end

  def render_hook(_module, %{__live_dev_tools_id__: id} = assigns) do
    Messaging.send_to_dashboards(%Events.Render{
      assigns: assigns,
      source: %{pid: self(), cid: nil, id: id}
    })

    :ok
  end

  def render_hook(_module, _assigns), do: :ok

  def handle_info_hook(_module, message, socket) do
    Messaging.send_to_dashboards(%Events.HandleInfo{
      message: message,
      source: %{pid: self(), cid: nil, id: Util.get_id(socket)}
    })

    {:cont, socket}
  end

  def handle_params_hook(_module, params, uri, socket) do
    Messaging.send_to_dashboards(%Events.HandleParams{
      params: params,
      source: %{pid: self(), cid: nil, id: Util.get_id(socket)},
      uri: uri
    })

    {:cont, socket}
  end

  def handle_event_hook(_module, "__dom_components__", %{"components" => components}, socket) do
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
      source: %{pid: self(), cid: nil, id: Util.get_id(socket)}
    })

    {:halt, socket}
  end

  def handle_event_hook(_module, event, params, socket) do
    Messaging.send_to_dashboards(%Events.HandleEvent{
      event: event,
      params: params,
      source: %{pid: self(), cid: nil, id: Util.get_id(socket)}
    })

    {:cont, socket}
  end
end
