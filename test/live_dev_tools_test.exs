defmodule LiveDevToolsTest do
  use ExUnit.Case
  doctest LiveDevTools

  test "greets the world" do
    assert LiveDevTools.hello() == :world
  end
end
