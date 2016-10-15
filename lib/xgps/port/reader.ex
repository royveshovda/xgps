defmodule XGPS.Port.Reader do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def get_gps_data(pid) do
    GenServer.call(pid, :get_gps_data)
  end

  def get_port_name(pid) do
    GenServer.call(pid, :get_port_name)
  end

  defmodule State do
    defstruct [
      gps_data: nil,
      pid: nil,
      port_name: nil
    ]
  end

  def init({port_name, :init_adafruit_gps}) do
    {:ok, uart_pid} = Nerves.UART.start_link
    :ok = Nerves.UART.configure(uart_pid, framing: {Nerves.UART.Framing.Line, separator: "\r\n"})
    :ok = Nerves.UART.open(uart_pid, port_name, speed: 9600, active: true)
    gps_data = %XGPS.GpsData{has_fix: false}
    state = %State{gps_data: gps_data, pid: uart_pid, port_name: port_name}
    init_adafruit_gps(uart_pid)
    {:ok, state}
  end

  def init({:simulate}) do
    gps_data = %XGPS.GpsData{has_fix: false}
    state = %State{gps_data: gps_data, pid: :simulate, port_name: :simulate}
    {:ok, state}
  end

  def init({port_name}) do
    {:ok, uart_pid} = Nerves.UART.start_link
    :ok = Nerves.UART.configure(uart_pid, framing: {Nerves.UART.Framing.Line, separator: "\r\n"})
    :ok = Nerves.UART.open(uart_pid, port_name, speed: 9600, active: true)
    gps_data = %XGPS.GpsData{has_fix: false}
    state = %State{gps_data: gps_data, pid: uart_pid, port_name: port_name}
    {:ok, state}
  end

  defp init_adafruit_gps(uart_pid) do
    cmd1 = "$PMTK313,1*2E\r\n" # enable SBAS
    cmd2 = "$PMTK319,1*24\r\n" # Set SBAS to not test mode
    cmd3 = "$PMTK301,2*2E\r\n" # Enable SBAS to be used for DGPS
    cmd4 = "$PMTK286,1*23\r\n" # Enable AIC (anti-inteference)
    cmd5 = "$PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*28\r\n" # Output only RMC & GGA
    cmd6 = "$PMTK397,0*23\r\n" # Disable nav-speed threshold
    Nerves.UART.write(uart_pid, cmd1)
    Nerves.UART.write(uart_pid, cmd2)
    Nerves.UART.write(uart_pid, cmd3)
    Nerves.UART.write(uart_pid, cmd4)
    Nerves.UART.write(uart_pid, cmd5)
    Nerves.UART.write(uart_pid, cmd6)
  end

  def handle_info({:nerves_uart, port_name, data}, %State{port_name: port_name} = state) do
    log_sentence(data)
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

  defp update_gps_data_and_send_notification(parsed_data, old_gps_data) do
    new_gps_data = update_gps_data(parsed_data, old_gps_data)
    Logger.debug(fn -> "New gps_data: : " <> inspect(new_gps_data) end)
    XGPS.Broadcaster.async_notify(new_gps_data)
    new_gps_data
  end

  defp will_update_gps_data?(%XGPS.Messages.RMC{}), do: true
  defp will_update_gps_data?(%XGPS.Messages.GGA{}), do: true
  defp will_update_gps_data?(_parsed), do: false

  defp log_sentence(sentence) do
    Logger.debug(fn -> "Received: " <> sentence end)
    sentence
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
    Nerves.UART.write(state.pid, (command <> "\r\n"))
    {:noreply, state}
  end

  def terminate(_reason, %State{port_name: :simulate}), do: :ok

  def terminate(_reason, state) do
    Nerves.UART.close(state.pid)
    Nerves.UART.stop(state.pid)
  end

  defp update_gps_data(%XGPS.Messages.RMC{} = rmc, gps_data) do
    speed = knots_to_kmh(rmc.speed_over_groud)
    %{gps_data | time: rmc.time,
                 date: rmc.date,
                 latitude: rmc.latitude,
                 longitude: rmc.longitude,
                 angle: rmc.track_angle,
                 magvariation: rmc.magnetic_variation,
                 speed: speed}
  end

  defp update_gps_data(%XGPS.Messages.GGA{fix_quality: 0}, gps_data) do
    %{gps_data | has_fix: false}
  end

  defp update_gps_data(%XGPS.Messages.GGA{} = gga, gps_data) do
    %{gps_data | has_fix: true,
                                fix_quality: gga.fix_quality,
                                satelites: gga.number_of_satelites_tracked,
                                hdop: gga.horizontal_dilution,
                                altitude: gga.altitude,
                                geoidheight: gga.height_over_goeid,
                                latitude: gga.latitude,
                                longitude: gga.longitude}
  end

  defp knots_to_kmh(speed_in_knots) when is_float(speed_in_knots) do
    speed_in_knots * 1.852
  end
  defp knots_to_kmh(_speed_in_knots), do: 0
end
