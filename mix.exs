defmodule KvUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:credo, "~> 1.5.0-rc.2", only: [:dev, :test], runtime: false},
      {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test]},
      {:ex_guard, github: "lastobelus/ex_guard", only: :dev}
    ]
  end

  # Releases package application code and all its dependencies, and the Erlang Virtual Machine and
  # runtime into a self-contained directory that can be packaged and deployed to a machine with the
  # same OS  and version.

  # Releases are created with `mix release` which looks at `MIX_ENV` environment variable for the
  # environment.

  # When creating a release from an umbrella app, we must define at least one release in the
  # root `mix.exs`.
  defp releases do
    [
      # this release will run the server and storage for buckets starting with a..m
      a_to_m: [
        version: "0.0.1",
        # permanent means if the application crashes, the whole node terminates
        applications: [kv_server: :permanent, kv: :permanent],
        cookie: "we-know-each-other"
      ],
      # this release will just run storage for buckets starting with n..z
      # to run the server on multiple nodes we would need to run them on
      # different ports and make the port configurable.
      n_to_z: [
        version: "0.0.1",
        applications: [kv: :permanent],
        cookie: "we-know-each-other"
      ]
    ]
  end
end
