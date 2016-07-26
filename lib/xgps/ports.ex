defmodule XGPS.Ports do
  use Supervisor

  def start_port(port_name) do
    Supervisor.start_child(__MODULE__, [{port_name}])
  end

  def get_running_port_names do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn({_, pid, :supervisor, _}) -> pid end)
    |> Enum.map(fn(pid) -> XGPS.Port.Supervisor.get_port_name(pid) end)
  end

  def get_one_position do
    children = Supervisor.which_children(__MODULE__)
    case length(children) do
      0 -> {:error, :no_port_running}
      _ ->
       {_, pid, :supervisor, _} = Enum.at(children, 0)
       gps_data = XGPS.Port.Supervisor.get_gps_data(pid)
       {:ok, gps_data}
    end
  end

  def send_simulated_position(lat, lon, alt) when is_float(lat) and is_float(lon) and is_float(alt) do
    now = DateTime.utc_now()
    send_simulated_position(lat, lon, alt, now)
  end

  def send_simulated_position(lat, lon, alt, date_time) when is_float(lat) and is_float(lon) and is_float(alt) do
    simulators = get_running_simulators()
    case length(simulators) do
      0 -> {:error, :no_simulator_running}
      _ ->
        {sim_pid, :simulate} = Enum.at(simulators, 0)

        XGPS.Port.Supervisor.send_simulated_position(sim_pid , lat, lon, alt, date_time)
        :ok
    end
  end

  def send_simulated_no_fix() do
    now = DateTime.utc_now()
    send_simulated_no_fix(now)
  end

  def send_simulated_no_fix(date_time) do
    simulators = get_running_simulators()
    case length(simulators) do
      0 -> {:error, :no_simulator_running}
      _ ->
        {sim_pid, :simulate} = Enum.at(simulators, 0)
        XGPS.Port.Supervisor.send_simulated_no_fix(sim_pid, date_time)
        :ok
    end
  end

  def start_link do
    result = {:ok, pid} = Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    start_port_if_defined_in_config(pid)
    result
  end

  defp start_port_if_defined_in_config(pid) do
    case Application.get_env(:xgps, :port_to_start, :no_port_to_start) do
      :no_port_to_start ->
        :ok
      portname_with_args ->
        Supervisor.start_child(pid, [portname_with_args])
    end
  end

  def init(:ok) do
    children = [
      supervisor(XGPS.Port.Supervisor, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  defp get_running_simulators do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn({_, pid, :supervisor, _}) -> pid end)
    |> Enum.map(fn(pid) -> {pid, XGPS.Port.Supervisor.get_port_name(pid)} end)
    |> Enum.filter(fn({_pid, port_name}) -> port_name == :simulate end)
  end
end
