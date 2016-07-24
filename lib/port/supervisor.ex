defmodule XGPS.Port.Supervisor do
  use Supervisor

  def get_gps_data(supervisor_pid) do
    [{_, reader_pid, _, _}] = Supervisor.which_children(supervisor_pid)
    XGPS.Port.Reader.get_gps_data(reader_pid)
  end

  def get_port_name(supervisor_pid) do
    [{_, reader_pid, _, _}] = Supervisor.which_children(supervisor_pid)
    XGPS.Port.Reader.get_gps_data(reader_pid) 
  end

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    children = [
      worker(XGPS.Port.Reader, [args], restart: :transient)
    ]
    supervise(children, strategy: :one_for_one)
  end
end
