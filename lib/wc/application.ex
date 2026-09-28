defmodule WC.Application do
  @moduledoc """
  Application callback for the `:wc` application.

  Burrito boots the release in embedded mode and expects the application to do
  the work and stop the VM, so `c:start/2` runs the CLI and halts.

  The `__BURRITO` guard keeps every other entry point untouched: the escript,
  `mix run` and `mix test` start this application too, but their arguments come
  from a different place, so the CLI is left to `WC.main/1`.
  """

  use Application

  @impl Application
  def start(_type, _args) do
    if System.get_env("__BURRITO") do
      # Burrito passes the CLI arguments through to the VM after `-extra`.
      WC.main(:init.get_plain_arguments() |> Enum.map(&to_string/1))
      System.halt(0)
    end

    # An application callback has to hand back a live process even when it has
    # nothing to supervise. OTP shuts it down with the application; the receive
    # never matches, so it just parks there.
    {:ok, spawn(fn -> receive do: (_ -> :ok) end)}
  end
end
