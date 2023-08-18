defmodule JudgeWorker.MixProject do
  use Mix.Project

  def project do
    [
      app: :judge_worker,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Worker.Application, []},
      extra_applications: [:lager, :logger, :amqp]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do  
    [
      {:amqp, "~> 1.0"},
    ]
  end
end
