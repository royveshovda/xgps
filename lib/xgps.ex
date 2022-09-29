defmodule XGPS do
  use Application

  def start(_type, _args) do
    children = [
      %{
        id: Ports,
        start: { XGPS.Ports, :start_link, []},
        type: :supervisor
      },
      %{
        id: Broadcaster,
        start: { XGPS.Broadcaster, :start_link, []},
        type: :worker
      },
    ]

    opts = [strategy: :one_for_one, name: XGPS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
