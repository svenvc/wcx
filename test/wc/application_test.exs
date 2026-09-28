defmodule WC.ApplicationTest do
  use ExUnit.Case, async: true

  describe "start/2" do
    test "starts outside of a Burrito binary and leaves the CLI alone" do
      System.delete_env("__BURRITO")

      assert {:ok, pid} = WC.Application.start(:normal, [])
      assert is_pid(pid)
    end
  end
end
