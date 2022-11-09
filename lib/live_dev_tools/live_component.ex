defmodule LiveDevTools.LiveComponent do
  defmacro __using__(_) do
    quote do
      @before_compile LiveDevTools.LiveComponent
    end
  end

  defmacro __before_compile__(env) do
    [
      wrap_mount(env),
      wrap_update(env),
      wrap_handle_event(env),
      wrap_render(env)
    ]
  end

  defp wrap_mount(env) do
    if Module.defines?(env.module, {:mount, 1}) do
      quote do
        defoverridable mount: 1

        def mount(socket) do
          socket
          |> LiveDevTools.LiveComponent.__handle_mount__()
          |> super()
        end
      end
    else
      quote do
        def mount(socket) do
          {:ok, LiveDevTools.LiveComponent.__handle_mount__(socket)}
        end
      end
    end
  end

  def __handle_mount__(socket) do
    if Phoenix.LiveView.connected?(socket) do
      id = LiveDevTools.Util.random_id()

      LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.Mount{
        module: __MODULE__,
        source: %{pid: self(), cid: socket.assigns.myself.cid, id: id}
      })

      LiveDevTools.Util.put_id(socket, id)
    else
      socket
    end
  end

  defp wrap_update(env) do
    if Module.defines?(env.module, {:update, 2}) do
      quote do
        defoverridable update: 2

        def update(assigns, socket) do
          super(assigns, LiveDevTools.LiveComponent.__handle_update__(socket, assigns))
        end
      end
    else
      quote do
        def update(assigns, socket) do
          {:ok, socket |> LiveDevTools.LiveComponent.__handle_update__(assigns) |> assign(assigns)}
        end
      end
    end
  end

  def __handle_update__(socket, %{__live_dev_tools_id__: id} = assigns) do
    LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.Update{
      assigns: assigns,
      source: %{pid: self(), cid: socket.assigns.myself.cid, id: id}
    })

    socket
  end

  def __handle_update__(socket, _assigns), do: socket

  defp wrap_handle_event(env) do
    if Module.defines?(env.module, {:handle_event, 3}) do
      quote do
        defoverridable handle_event: 3

        def handle_event(event, params, socket) do
          LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.HandleEvent{
            event: event,
            params: params,
            source: %{pid: self(), cid: socket.assigns.myself.cid, id: LiveDevTools.Util.get_id(socket)}
          })

          super(event, params, socket)
        end
      end
    else
      quote do
        def handle_event(event, params, socket) do
          LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.HandleEvent{
            event: event,
            params: params,
            source: %{pid: self(), cid: socket.assigns.myself.cid, id: LiveDevTools.Util.get_id(socket)}
          })

          {:noreply, socket}
        end
      end
    end
  end

  defp wrap_render(_env) do
    quote do
      defoverridable render: 1

      def render(assigns) do
        LiveDevTools.LiveComponent.__handle_render__(assigns)
        super(assigns)
      end
    end
  end

  def __handle_render__(%{__live_dev_tools_id__: id} = assigns) do
    LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.Render{
      assigns: assigns,
      source: %{pid: self(), cid: assigns.myself.cid, id: id}
    })

    :ok
  end

  def __handle_render__(_assigns), do: :ok
end
