defmodule XGPS.Mixfile do
  use Mix.Project

  def project do
    [app: :xgps,
     name: XGPS,
     version: "0.1.0",
     elixir: "~> 1.3.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/rveshovda/xgps",
     deps: deps()]
  end

  def application do
    [applications: [:logger],
     mod: {XGPS, []}]
  end

  defp deps do
    [{:nerves_uart, "~> 0.0.7"}]
  end
end
