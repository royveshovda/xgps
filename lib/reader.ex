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

  def command_antenna_on do
    cmd = "$PGCMD,33,1*6C"
    send_command(cmd)
  end

  def command_antenna_off do
    cmd = "$PGCMD,33,0*6D"
    send_command(cmd)
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
      satelites: nil,
    ]
  end

  #uint8_t hour, minute, seconds, year, month, day;
  #uint16_t milliseconds;
  #float latitude, longitude;
  #float geoidheight, altitude;
  #float speed, angle, magvariation, HDOP;
  #uint8_t fixquality, satellites;

  def init(port_name) do
    {:ok, pid} = Nerves.UART.start_link
    :ok = Nerves.UART.open(pid, port_name, speed: 9600, active: true)
    gps_data = %Gps_state{has_fix: false}
    state = %State{gps_data: gps_data, pid: pid, port_name: port_name, data_buffer: ""}
    {:ok, state}
  end

  # TODO: Use struct as state

  def handle_info({:nerves_uart, _port_name, "$"}, %State{data_buffer: ""} = state) do
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _port_name, "$"}, state) do
    sentence = String.strip(("$" <> state.data_buffer))
    # TODO: send to subscribers
    IO.puts(sentence)
    IO.inspect XGPS.Parser.parse_sentence(sentence)

    # TODO: Update state based on parse result
    {:noreply, %{state | data_buffer: ""}}
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
end
