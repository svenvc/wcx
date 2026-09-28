defmodule WC.Release do
  @moduledoc """
  Release step that wraps the application in a Burrito binary.

  Burrito resolves the prebuilt ERTS from its own default resolver, so ours is
  registered first to pin the ERTS version (see `WC.Release.ERTSResolver`).
  """

  @doc """
  Wraps `release` in a Burrito binary for every configured target.
  """
  def wrap(%Mix.Release{} = release) do
    Burrito.register_erts_resolver(WC.Release.ERTSResolver)
    Burrito.wrap(release)
  end
end
