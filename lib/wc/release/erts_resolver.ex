defmodule WC.Release.ERTSResolver do
  @moduledoc """
  Pins the prebuilt ERTS that Burrito bundles into the binaries.

  Burrito asks the BEAM Machine for the ERTS matching the Erlang that is running
  the build, but the BEAM Machine only publishes some of those: a patch-level host
  such as 29.1.1 has no tarball and the fetch 404s, while 29.1 has one. Rewriting
  the version keeps local and CI builds reproducible no matter which Erlang is
  installed.

  The rewrite happens here rather than through Burrito's `:custom_erts` option
  because a target with a custom ERTS no longer counts as precompiled, which
  skips the musl step that Linux binaries need.

  Bump the pinned version when a newer one is published, for every target at
  `https://beam-machine-universal.b-cdn.net/` (macOS, Linux) and
  `https://github.com/erlang/otp/releases` (Windows).
  """

  @behaviour Burrito.Util.ERTSResolver

  alias Burrito.Builder.Target

  @erts_version "29.1"

  @doc """
  The prebuilt ERTS release every binary is bundled with.
  """
  def erts_version, do: @erts_version

  @impl Burrito.Util.ERTSResolver
  def do_resolve(%Target{} = target) do
    target
    |> pin_erts()
    |> Burrito.Util.DefaultERTSResolver.do_resolve()
  end

  @doc """
  Points a precompiled ERTS request at the pinned version.

  Leaves any other ERTS source, such as one set through `:custom_erts`, alone.
  """
  def pin_erts(%Target{erts_source: {:precompiled, _}} = target) do
    %Target{target | erts_source: {:precompiled, version: @erts_version}}
  end

  def pin_erts(%Target{} = target), do: target
end
