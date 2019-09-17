defmodule SSD1322.MixProject do
  use Mix.Project

  def project do
    [
      app: :ssd1322,
      version: "0.2.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/mtrudel/ssd1322"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:circuits_spi, "~> 0.1"},
      {:circuits_gpio, "~> 0.1"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp description do
    "A library for interfacing with SSD1322 based OLED displays"
  end

  defp package() do
    [
      files: ["lib", "test", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Mat Trudel"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mtrudel/ssd1322"}
    ]
  end
end
