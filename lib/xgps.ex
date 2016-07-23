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
    pid_sup = Supervisor.start_link(children, opts)

    #args = Application.get_env(:xgps, :port_to_start)
    #XGPS.Ports_supervisor.start_port_on_startup(args) 

    pid_sup
  end
end
