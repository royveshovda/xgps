defmodule XGPS.Ports_supervisor do
  use Supervisor

  def start_port(port_name) do
    pid = Process.whereis(__MODULE__)
    Supervisor.start_child(pid, [{port_name}])
  end

  def get_running_port_names do
    pid = Process.whereis(__MODULE__)
    Supervisor.which_children(pid)
  end

  def start_link do
    result = {:ok, pid} = Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    # Start port if defined in config
    case Application.get_env(:xgps, :port_to_start, :no_port_to_start) do
      :no_port_to_start ->
        :ok
      portname_with_args ->
        Supervisor.start_child(pid, [portname_with_args])
    end
    result
  end

  def init(:ok) do
    children = [
      worker(XGPS.Port.Supervisor, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
