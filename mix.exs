defmodule Siariwyd.Mixfile do
  use Mix.Project

  @version "0.2.0"

  def project do
    [app: :siariwyd,
     version: @version,
     elixir: "~> 1.4",
     description: description(),
     package: package(),
     source_url: "https://github.com/ianrumford/siariwyd",
     homepage_url: "https://github.com/ianrumford/siariwyd",
     docs: [extras: ["./README.md", "./CHANGELOG.md"]],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.14.5", only: :dev},
    ]
  end

  defp package do
    [maintainers: ["Ian Rumford"],
     files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/ianrumford/siariwyd"}]
  end

  defp description do
  """
  Siariwyd: Sharing and Reusing Functions' Implementations that must be compiled together.
  """
  end

end
