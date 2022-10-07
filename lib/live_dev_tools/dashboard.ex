defmodule LiveDevTools.Dashboard do
  @moduledoc false
  use Phoenix.LiveComponent

  import LiveDevTools.Util
  alias LiveDevTools.SourceNode

  defp live_views(views) do
    Enum.filter(views, &(&1.cid == nil))
  end
end
