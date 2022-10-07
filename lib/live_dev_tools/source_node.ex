defmodule LiveDevTools.SourceNode do
  use Phoenix.LiveComponent
  import LiveDevTools.Util

  def mount(socket) do
    {:ok, assign(socket, expanded?: false)}
  end

  def handle_event("toggle-expanded", _, socket) do
    {:noreply, assign(socket, :expanded?, not socket.assigns.expanded?)}
  end

  defp child_views(all_views, this_view) do
    Enum.filter(all_views, fn view -> view.parent_cid == this_view.cid and view.cid != nil end)
  end
end
