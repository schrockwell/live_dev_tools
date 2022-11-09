defmodule LiveDevTools.Util do
  @moduledoc false

  def random_id do
    Base.encode64(:crypto.strong_rand_bytes(10), padding: false)
  end

  def put_id(socket, id) do
    # TODO: Support LiveView 0.18 with Phoenix.LiveComponent.assign/3
    Phoenix.LiveView.assign(socket, :__live_dev_tools_id__, id)
  end

  def get_id(%Phoenix.LiveView.Socket{} = socket), do: get_id(socket.assigns)
  def get_id(assigns), do: assigns.__live_dev_tools_id__

  def module_name(module) when is_atom(module) do
    Application.get_env(:live_dev_tools, :prefixes, [])
    |> Enum.map(fn prefix -> "#{inspect(prefix)}." end)
    |> Enum.find(fn prefix ->
      String.starts_with?(inspect(module), prefix)
    end)
    |> case do
      nil -> inspect(module)
      prefix -> String.trim_leading(inspect(module), prefix)
    end
  end

  def source_name(%{pid: pid, module: module, cid: nil}) do
    "#{module_name(module)} (#{inspect(pid)})"
  end

  def source_name(%{pid: pid, module: module, cid: cid}) do
    "#{module_name(module)} (#{inspect(pid)}) (#{inspect(cid)})"
  end

  def source_slug(%{pid: pid, module: module, cid: nil}) do
    ~r/[^a-zA-Z0-9]+/
    |> Regex.replace("#{inspect(pid)}-#{inspect(module)}", "-")
    |> String.trim("-")
  end

  def source_slug(%{pid: pid, module: module, cid: cid}) do
    ~r/[^a-zA-Z0-9]+/
    |> Regex.replace("#{inspect(pid)}-#{inspect(module)}-#{cid}", "-")
    |> String.trim("-")
  end
end
