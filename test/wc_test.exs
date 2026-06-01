defmodule WCTest do
  use ExUnit.Case
  doctest WC

  test "greets the world" do
    assert WC.hello() == :world
  end
end
