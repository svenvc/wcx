defmodule WC.MixProject do
  use Mix.Project

  def project do
    [
      app: :wc,
      version: "0.2.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: WC],
      releases: releases(),
      # The application callback and the release step only do their work inside a
      # standalone binary, which `mix release` and `test/smoke.sh` cover, so keep
      # them out of the coverage summary.
      test_coverage: [ignore_modules: [~r/^WC\.(Application|Release)/]],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {WC.Application, []}
    ]
  end

  # The release name determines the binary name, so it stays `wc`.
  # BURRITO_TARGET=<alias> mix release builds a single target.
  defp releases do
    [
      wc: [
        steps: [:assemble, &WC.Release.wrap/1],
        burrito: [
          targets: [
            macos_x86_64: [os: :darwin, cpu: :x86_64],
            macos_arm64: [os: :darwin, cpu: :aarch64],
            linux_x86_64: [os: :linux, cpu: :x86_64],
            linux_arm64: [os: :linux, cpu: :aarch64],
            windows_x86_64: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Build-time only: the release step runs at `mix release` time, so the app
      # never needs Burrito in the payload.
      {:burrito, "~> 1.6", runtime: false}
    ]
  end
end
