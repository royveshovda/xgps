defmodule XGPS.Port.Supervisor do
  use Supervisor

  def start_link([port_name]) do
    name = to_string(__MODULE__) <> ": " <> port_name
    Supervisor.start_link(__MODULE__, [port_name], name: name)
  end

  def init([port_name]) do
    children = [
      worker(XGPS.Port.Reader, [port_name], restart: :transient),
    ]
    supervise(children, strategy: :one_for_one, max_restarts: 3, max_seconds: 5)
  end
end
