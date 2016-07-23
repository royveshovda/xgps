defmodule XGPS do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(XGPS.Ports_supervisor, []),
      XGPS.EventManager.child_spec,
      #worker(XGPS.Parser, [])
    ]

    opts = [strategy: :one_for_one, name: XGPS.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts),
          :ok <- XGPS.EventHandler.register_with_manager,
    do: {:ok, pid}
  end
end
