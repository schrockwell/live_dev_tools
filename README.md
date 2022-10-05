# LiveDevTools

**TODO: Add description**

## Installation

The package can be installed by adding `live_dev_tools` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_dev_tools, "~> 0.1.0"}
  ]
end
```

Update the Phoenix macros (do not leave these in for production!!!) to hook into the lifecycles:

```elixir
# lib/my_app_web.ex

defmodule MyAppWeb do
  def live_component do
    quote do
      use LiveDevTools.LiveComponent
    end
  end

  def live_view do
    quote do
      use LiveDevTools.LiveView
    end
  end
end
```

Add the page to the Dashboard:

```elixir
# lib/my_app_web/router.ex

live_dashboard "/live_dashboard",
  metrics: MyAppWeb.Telemetry,
  additional_pages: [
    dev_tools: LiveDevTools.DashboardPage
  ]
```

Open up the dashboard, then visit any any LiveView in another tab.
