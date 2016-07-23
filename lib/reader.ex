defmodule XGPS.Reader do
  use GenServer

  # Only for debugging
  def serial0() do
    start_link("/dev/serial0")
  end

  def start_link(port_name) do
    GenServer.start_link(__MODULE__, port_name, name: __MODULE__)
  end


  def stop() do
    stop(__MODULE__)
  end

  defp stop(name) do
    pid = Process.whereis(name)
    cond do
      is_pid(pid) ->
        if Process.alive?(pid) do
          GenServer.call(pid, :stop)
        end
      true -> :ok
    end
    :ok
  end

  def command_output_off do
    cmd = "$PMTK314,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*28"
    send_command(cmd)
  end

  def command_output_all_data do
    cmd = "$PMTK314,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0*28"
    send_command(cmd)
  end

  def command_output_rmc_gga do
    cmd = "$PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*28"
    send_command(cmd)
  end

  def command_output_rmc_only do
    cmd = "$PMTK314,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*29"
    send_command(cmd)
  end

  def command_ask_for_version do
    cmd = "$PMTK605*31"
    send_command(cmd)
  end

  def command_send_antenna_on do
    cmd = "$PGCMD,33,1*6C"
    send_command(cmd)
  end

  def command_send_antenna_off do
    cmd = "$PGCMD,33,0*6D"
    send_command(cmd)
  end

  def command_init_adafruit do
    cmd1 = "$PMTK313,1*2E" # enable SBAS
    cmd2 = "$PMTK319,1*24" # Set SBAS to not test mode
    cmd3 = "$PMTK301,2*2E" # Enable SBAS to be used for DGPS
    cmd4 = "$PMTK286,1*23" # Enable AIC (anti-inteference)
    cmd5 = "$PMTK314,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*29" # Output only RMC & GGA
    send_command(cmd1)
    send_command(cmd2)
    send_command(cmd3)
    send_command(cmd4)
    send_command(cmd5)
  end

  defp send_command(command) do
    pid = Process.whereis(__MODULE__)
    GenServer.cast(pid, {:command, command})
  end

  ######

  defmodule State do
    defstruct [
      gps_data: nil,
      pid: nil,
      port_name: nil,
      data_buffer: nil
    ]
  end

  defmodule Gps_state do
    defstruct [
      has_fix: false,
      time: nil,
      date: nil,
      latitude: nil,
      longitude: nil,
      geoidheight: nil,
      altitude: nil,
      speed: nil,
      angle: nil,
      magvariation: nil,
      hdop: nil,
      fix_quality: nil,
      satelites: nil
    ]
  end

  def init(port_name) do
    {:ok, pid} = Nerves.UART.start_link
    :ok = Nerves.UART.open(pid, port_name, speed: 9600, active: true)
    gps_data = %Gps_state{has_fix: false}
    state = %State{gps_data: gps_data, pid: pid, port_name: port_name, data_buffer: ""}
    {:ok, state}
  end

  # TODO: Use struct as state

  def handle_info({:nerves_uart, _port_name, "\n"}, %State{data_buffer: ""} = state) do
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _port_name, "\n"}, state) do
    sentence = String.strip((state.data_buffer))

    # TODO: Remove after debugging
    IO.puts sentence
    parsed_data = XGPS.Parser.parse_sentence(sentence)

    {updated, new_gps_data} = update_gps_data(parsed_data, state.gps_data)
    send_update_event({updated, new_gps_data})

    # TODO: Remove after debugging
    IO.inspect new_gps_data
    {:noreply, %{state | data_buffer: "", gps_data: new_gps_data}}
  end

  def handle_info({:nerves_uart, _port_name, data}, state) do
    data_buffer = state.data_buffer <> data
    {:noreply, %{state | data_buffer: data_buffer}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:command, command}, state) do
    Nerves.UART.write(state.pid, (command <> "\r\n"))
    {:noreply, state}
  end

  def terminate(_reason, state) do
    Nerves.UART.close(state.pid)
    Nerves.UART.stop(state.pid)
  end

  defp update_gps_data(%XGPS.Messages.RMC{} = rmc, gps_data) do
    speed = knots_to_kmh(rmc.speed_over_groud)
    new_gps_data = %{gps_data | time: rmc.time,
                                date: rmc.date,
                                latitude: rmc.latitude,
                                longitude: rmc.longitude,
                                angle: rmc.track_angle,
                                magvariation: rmc.magnetic_variation,
                                speed: speed}
    {:updated, new_gps_data}
  end

  defp update_gps_data(%XGPS.Messages.GGA{fix_quality: 0}, gps_data) do
    new_gps_data = %{gps_data | has_fix: false}
    {:updated, new_gps_data}
  end

  defp update_gps_data(%XGPS.Messages.GGA{} = gga, gps_data) do
    new_gps_data = %{gps_data | has_fix: true,
                                fix_quality: gga.fix_quality,
                                satelites: gga.number_of_satelites_tracked,
                                hdop: gga.horizontal_dilution,
                                altitude: gga.altitude,
                                geoidheight: gga.height_over_goeid,
                                latitude: gga.latitude,
                                longitude: gga.longitude}
    {:updated, new_gps_data}
  end

  defp update_gps_data(_message, gps_data) do
    {:not_updated, gps_data}
  end

  defp knots_to_kmh(speed_in_knots) when is_float(speed_in_knots) do
    speed_in_knots * 1.852
  end
  defp knots_to_kmh(_speed_in_knots), do: 0

  defp send_update_event({:not_updated, _gps_data}), do: :ok
  defp send_update_event({:updated, _gps_data}) do
    # TODO: Push updates using GenEvent
    :ok
  end
end
