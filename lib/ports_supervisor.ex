defmodule XGPS.Ports_supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_port(port_name) do
    pid = Process.whereis(__MODULE__)
    Supervisor.start_child(pid, [{port_name}])
  end

  def start_port_with_args(args) do
    pid = Process.whereis(__MODULE__)
    Supervisor.start_child(pid, [args])
  end

  def init(:ok) do
    children = [
      worker(XGPS.Port.Supervisor, [], restart: :transient)
    ]

    # Start port if defined in config
    case Application.get_env(:xgps, :port_to_start, :no_port_to_start) do
      :no_port_to_start ->
        supervise(children, strategy: :simple_one_for_one, max_restarts: 3, max_seconds: 5)
      portname_with_args ->
        with {:ok, sup_pid} <- supervise(children, strategy: :simple_one_for_one, max_restarts: 3, max_seconds: 5),
              :ok <- XGPS.Ports_supervisor.start_port_with_args(portname_with_args),
        do: {:ok, sup_pid}
    end
  end
end
