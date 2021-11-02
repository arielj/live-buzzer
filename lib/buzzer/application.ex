defmodule Buzzer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BuzzerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Buzzer.PubSub},
      # Start the Endpoint (http/https)
      BuzzerWeb.Endpoint,
      Buzzer.Presence
      # Start a worker by calling: Buzzer.Worker.start_link(arg)
      # {Buzzer.Worker, arg}
    ]

    :ets.new(:buzzing, [:set, :public, :named_table])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Buzzer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BuzzerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
