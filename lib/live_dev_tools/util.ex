defmodule LiveDevTools.Util do
  @moduledoc false

  alias LiveDevTools.LiveComponentSource
  alias LiveDevTools.LiveViewSource

  def module_name(module) do
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

  def source_name(%LiveViewSource{pid: pid, module: module}) do
    "#{module_name(module)} (#{inspect(pid)})"
  end

  def source_name(%LiveComponentSource{pid: pid, module: module, cid: cid}) do
    "#{module_name(module)} (#{inspect(pid)}) (#{inspect(cid.cid)})"
  end
end
