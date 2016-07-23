defmodule XGPS.Ports_supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_port(port_name) do
    pid = Process.whereis(__MODULE__)
    Supervisor.start_child(pid, [{port_name}])
  end

  def start_port_with_adafruit_init(port_name) do
    Supervisor.start_child(__MODULE__, [{port_name, :init_adafruit_gps}])
  end

  def start_port_on_startup(args) do
    pid = Process.whereis(__MODULE__)
    Supervisor.start_child(pid, [args])
  end

  # Only for debugging
  def serial0_start() do
    start_port_with_adafruit_init("/dev/serial0")
  end

  def init(:ok) do
    children = [
      worker(XGPS.Port.Supervisor, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one, max_restarts: 3, max_seconds: 5)
  end
end
