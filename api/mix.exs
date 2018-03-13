defmodule Perseids.Mixfile do
  use Mix.Project

  def project do
    [app: :perseids,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Perseids, []},
     applications: [
       :phoenix,
       :phoenix_pubsub,
       :phoenix_ecto,
       :cowboy,
       :logger,
       :gettext,
       :mongodb,
       :poolboy,
       :corsica,
       :absinthe,
       :absinthe_plug,
       :httpoison,
       :scrivener_list,
       :bamboo,
       :bamboo_smtp,
       :uuid
     ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.3.0"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.0"},
     {:mongodb, ">= 0.0.0"},
     {:poolboy, ">= 0.0.0"},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:corsica, "~> 0.5"},
     {:absinthe, "~> 1.3.0"},
     {:absinthe_plug, "~> 1.3.0"},
     # dodanie path powoduje rekompilację tej zależności za każdym restartem, przydatne do dbg
     # {:httpoison, "~> 0.11.1", path: "deps/httpoison"},
     {:httpoison, "~> 0.11.1"},
     {:scrivener_list, "~> 1.0"},
     {:bamboo, "~> 0.8"},
     {:bamboo_smtp, "~> 1.4.0"},
     {:uuid, "~> 1.1"}
   ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
