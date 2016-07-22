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

  def init(port_name) do
    {:ok, pid} = Nerves.UART.start_link
    :ok = Nerves.UART.open(pid, port_name, speed: 9600, active: true)
    {:ok, %{pid: pid, port_name: port_name, data: ""}}
  end

  def handle_info({:nerves_uart, port_name, "$"}, %{pid: pid, port_name: port_name, data: ""}) do
    {:noreply, %{pid: pid, port_name: port_name, data: ""}}
  end

  def handle_info({:nerves_uart, port_name, "$"}, %{pid: pid, port_name: port_name, data: data}) do
    sentence = String.strip(("$" <> data))
    # TODO: send to subscribers
    IO.puts(sentence)
    IO.inspect XGPS.Parser.parse_sentence(sentence)
    {:noreply, %{pid: pid, port_name: port_name, data: ""}}
  end

  def handle_info({:nerves_uart, port_name, data}, %{pid: pid, port_name: port_name, data: old_data}) do
    {:noreply, %{pid: pid, port_name: port_name, data: old_data <> data}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:command, command}, %{pid: pid, port_name: _port_name, data: _data} = state) do
    Nerves.UART.write(pid, (command <> "\r\n"))
    {:noreply, state}
  end

  def terminate(_reason, %{pid: pid, port_name: _port_name}) do
    Nerves.UART.close(pid)
    Nerves.UART.stop(pid)
  end
end
