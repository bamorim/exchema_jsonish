defmodule ExchemaJSONish.MixProject do
  use Mix.Project

  def project do
    [
      app: :exchema_jsonish,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exchema, "~> 0.3.0"},
      {:exchema_coercion, github: "bamorim/exchema_coercion", only: :test},
      {:exchema_stream_data, github: "bamorim/exchema_stream_data", only: :test},
      {:stream_data, "~> 0.4.2", only: :test}
    ]
  end
end
