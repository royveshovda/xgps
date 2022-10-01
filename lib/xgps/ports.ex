defmodule XGPS.Ports do
  use DynamicSupervisor

  @doc """
  Open one port to be consumed. Needs to have one GPS attached to the port to work.
  To simulate, give port_name = :simulate
  """
  def start_port(port_name) do
    child =
    %{
      id: XGPS.Port.Supervisor,
      start: {XGPS.Port.Supervisor, :start_link, [port_name]},
      restart: :transient,
      type: :supervisor
    }
    DynamicSupervisor.start_child(__MODULE__, child)
  end

  def start_simulator(file_name) do
    child =
    %{
      id: XGPS.Port.Reader,
      start: {XGPS.Port.Supervisor, :start_link, [{:simulate, file_name}]},
      restart: :transient,
      type: :supervisor
    }
    DynamicSupervisor.start_child(__MODULE__, child)
  end

  def stop_simulator() do
    stop_port(:simulate)
  end

  def stop_port(port_name_to_stop) do
    children =
      Supervisor.which_children(__MODULE__)
      |> Enum.map(fn({_, pid, :supervisor, _}) -> pid end)
      |> Enum.map(fn(pid) -> {pid, XGPS.Port.Supervisor.get_port_name(pid)} end)
      |> Enum.filter(fn({_pid, port_name}) -> port_name == port_name_to_stop end)
      |> Enum.map(fn({pid, _port_name}) -> pid end)

    case length(children) do
      0 -> {:ok, :no_port_running}
      1 ->
        pid = Enum.at(children, 0)
        :ok = DynamicSupervisor.stop(pid)
    end
  end

  @doc """
  Return all the connected port names
  """
  def get_running_port_names do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn({_, pid, :supervisor, _}) -> pid end)
    |> Enum.map(fn(pid) -> XGPS.Port.Supervisor.get_port_name(pid) end)
  end

  @doc """
  Return the latest position if atteched to GPS.
  """
  def get_one_position do
    children = DynamicSupervisor.which_children(__MODULE__)
    case length(children) do
      0 -> {:error, :no_port_running}
      _ ->
       {_, pid, :supervisor, _} = Enum.at(children, 0)
       gps_data = XGPS.Port.Supervisor.get_gps_data(pid)
       {:ok, gps_data}
    end
  end

  @doc """
  Will send one GPS report as the give position.
  Since this will effectively generate both RMC and GGA sentences, the broadcaster will produce two values
  """
  def send_simulated_position(lat, lon, alt) when is_float(lat) and is_float(lon) and is_float(alt) do
    now = DateTime.utc_now()
    send_simulated_position(lat, lon, alt, now)
  end

  @doc """
  Will send one GPS report as the give position.
  Since this will effectively generate both RMC and GGA sentences, the broadcaster will produce two values
  """
  def send_simulated_position(lat, lon, alt, date_time) when is_float(lat) and is_float(lon) and is_float(alt) do
    simulators = get_running_simulators()
    case length(simulators) do
      0 -> {:error, :no_simulator_running}
      _ ->
        {sim_pid, :simulate} = Enum.at(simulators, 0)

        XGPS.Port.Supervisor.send_simulated_position(sim_pid, lat, lon, alt, date_time)
        :ok
    end
  end

  def reset_simulated_port_state() do
    simulators = get_running_simulators()
    case length(simulators) do
      0 -> {:error, :no_simulator_running}
      _ ->
        {sim_pid, :simulate} = Enum.at(simulators, 0)

        XGPS.Port.Supervisor.reset_simulated_port_state(sim_pid)
        :ok
    end
  end

  @doc """
  Will send one GPS report as no fix.
  Since this will effectively generate both RMC and GGA sentences, the broadcaster will produce two values
  """
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
    result = {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    start_port_if_defined_in_config(pid)
    result
  end

  defp start_port_if_defined_in_config(pid) do
    case Application.get_env(:xgps, :port_to_start) do
      nil ->
        :ok
      portname_with_args ->
        IO.puts("Start port directly")
        child =
          %{
            id: XGPS.Port.Supervisor,
            start: {XGPS.Port.Supervisor, :start_link, [portname_with_args]},
            restart: :transient,
            type: :supervisor
          }
        res = {:ok, _pid} = DynamicSupervisor.start_child(pid, child)
        res
    end
  end

  # Callbacks

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def get_running_simulators do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn({_, pid, :supervisor, _}) -> pid end)
    |> Enum.map(fn(pid) -> {pid, XGPS.Port.Supervisor.get_port_name(pid)} end)
    |> Enum.filter(fn({_pid, port_name}) -> port_name == :simulate end)
  end
end
