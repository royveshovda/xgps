defmodule XGPS.Port.Reader do
  use GenServer

  require Logger

  alias Circuits.UART
  alias XGPS.Driver.State

  # For legacy purpose
  def start_link({port_name, :init_adafruit_gps}),
    do: start_link({port_name, XGPS.Driver.AdafruitGps})

  def start_link({:simulate}),
    do: GenServer.start_link(__MODULE__, :simulate)

  def start_link({port_name}) when is_binary(port_name),
    do: start_link({port_name, XGPS.Driver.Generic})

  def start_link({port_name, mod}) when is_atom(mod),
    do: GenServer.start_link(__MODULE__, {port_name, mod})

  def start_link({port_name, driver}) when is_binary(driver) do
    mod = :"Elixir.XGPS.Driver.#{driver}"
    GenServer.start_link(__MODULE__, {port_name, mod})
  end

  def get_gps_data(pid) do
    GenServer.call(pid, :get_gps_data)
  end

  def get_port_name(pid) do
    GenServer.call(pid, :get_port_name)
  end

  ###
  ### Callbacks
  ###
  def init({port_name, mod}) do
    Logger.info("Start receiver #{mod} on port #{port_name}")
    {:ok, uart_pid} = UART.start_link()

    gps_data = %XGPS.GpsData{has_fix: false}

    {:ok, state} =
      %State{gps_data: gps_data, pid: uart_pid, port_name: port_name, mod: mod}
      |> mod.init()

    {:ok, state}
  end

  def handle_info({:circuits_uart, port_name, data}, %{port_name: port_name} = state) do
    Logger.debug(fn -> inspect(data) end)
    parsed_sentence = XGPS.Parser.parse_sentence(data)

    new_gps_data =
      case will_update_gps_data?(parsed_sentence) do
        true ->
          update_gps_data_and_send_notification(parsed_sentence, state.gps_data)

        false ->
          state.gps_data
      end

    {:noreply, %{state | gps_data: new_gps_data}}
  end

  def handle_info({:simulator, :simulate, :reset_gps_state}, %State{port_name: :simulate} = state) do
    {:noreply, %{state | gps_data: %XGPS.GpsData{has_fix: false}}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_call(:get_gps_data, _from, state) do
    {:reply, state.gps_data, state}
  end

  def handle_call(:get_port_name, _from, state) do
    {:reply, state.port_name, state}
  end

  def handle_cast({:command, command}, state) do
    UART.write(state.pid, command <> "\r\n")
    {:noreply, state}
  end

  def terminate(_reason, %State{port_name: :simulate}), do: :ok

  def terminate(_reason, state) do
    UART.close(state.pid)
    UART.stop(state.pid)
  end

  ###
  ### Priv
  ###
  defp update_gps_data_and_send_notification(parsed_data, old_gps_data) do
    new_gps_data = update_gps_data(parsed_data, old_gps_data)
    Logger.debug(fn -> "New gps_data: : " <> inspect(new_gps_data) end)
    XGPS.Broadcaster.async_notify(new_gps_data)
    new_gps_data
  end

  defp will_update_gps_data?(%XGPS.Messages.RMC{}), do: true
  defp will_update_gps_data?(%XGPS.Messages.GGA{}), do: true
  defp will_update_gps_data?(_parsed), do: false

  defp update_gps_data(%XGPS.Messages.RMC{} = rmc, gps_data) do
    speed = knots_to_kmh(rmc.speed_over_groud)

    %{
      gps_data
      | time: rmc.time,
        date: rmc.date,
        latitude: rmc.latitude,
        longitude: rmc.longitude,
        angle: rmc.track_angle,
        magvariation: rmc.magnetic_variation,
        speed: speed
    }
  end

  defp update_gps_data(%XGPS.Messages.GGA{fix_quality: 0}, gps_data) do
    %{gps_data | has_fix: false}
  end

  defp update_gps_data(%XGPS.Messages.GGA{} = gga, gps_data) do
    %{
      gps_data
      | has_fix: true,
        fix_quality: gga.fix_quality,
        satelites: gga.number_of_satelites_tracked,
        hdop: gga.horizontal_dilution,
        altitude: gga.altitude,
        geoidheight: gga.height_over_goeid,
        latitude: gga.latitude,
        longitude: gga.longitude
    }
  end

  defp knots_to_kmh(speed_in_knots) when is_float(speed_in_knots) do
    speed_in_knots * 1.852
  end

  defp knots_to_kmh(_speed_in_knots), do: 0
end
