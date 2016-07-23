defmodule XGPS do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(XGPS.Ports_supervisor, []),
      worker(XGPS.Publisher, [])
      #worker(XGPS.Parser, [])
    ]

    opts = [strategy: :one_for_one, name: XGPS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
