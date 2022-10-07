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
          if connected?(socket) do
            LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.Mount{
              module: __MODULE__,
              source: %{pid: self(), cid: socket.assigns.myself.cid}
            })
          end

          super(socket)
        end
      end
    else
      quote do
        def mount(socket) do
          if connected?(socket) do
            LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.Mount{
              module: __MODULE__,
              source: %{pid: self(), cid: socket.assigns.myself.cid}
            })
          end

          {:ok, socket}
        end
      end
    end
  end

  defp wrap_update(env) do
    if Module.defines?(env.module, {:update, 2}) do
      quote do
        defoverridable update: 2

        def update(assigns, socket) do
          LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.Update{
            assigns: assigns,
            source: %{pid: self(), cid: socket.assigns.myself.cid}
          })

          super(assigns, socket)
        end
      end
    else
      quote do
        def update(assigns, socket) do
          LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.Update{
            assigns: assigns,
            source: %{pid: self(), cid: socket.assigns.myself.cid}
          })

          {:ok, assign(socket, assigns)}
        end
      end
    end
  end

  defp wrap_handle_event(env) do
    if Module.defines?(env.module, {:handle_event, 3}) do
      quote do
        defoverridable handle_event: 3

        def handle_event(event, params, socket) do
          LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.HandleEvent{
            event: event,
            params: params,
            source: %{pid: self(), cid: socket.assigns.myself.cid}
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
            source: %{pid: self(), cid: socket.assigns.myself.cid}
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
        LiveDevTools.Messaging.send_to_dashboards(%LiveDevTools.Events.Render{
          assigns: assigns,
          source: %{pid: self(), cid: assigns.myself.cid}
        })

        super(assigns)
      end
    end
  end
end
