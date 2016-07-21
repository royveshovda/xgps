defmodule XGPS.Reader do
  use GenServer

  # Onlu for debugging
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

  def init(port_name) do
    {:ok, pid} = Nerves.UART.start_link
    :ok = Nerves.UART.open(pid, port_name, speed: 9600, active: true)
    Nerves.UART.write(pid, "$PGCMD,33,1*6C\r\n")
    {:ok, %{pid: pid, port_name: port_name, data: ""}}
  end

  def handle_info({:nerves_uart, port_name, "$"}, %{pid: pid, port_name: port_name, data: ""}) do
    {:noreply, %{pid: pid, port_name: port_name, data: ""}}
  end

  def handle_info({:nerves_uart, port_name, "$"}, %{pid: pid, port_name: port_name, data: data}) do
    sentence = String.strip(("$" <> data))
    # TODO: send to subscribers
    # IO.puts(sentence)
    IO.inspect XGPS.Parser.parse_sentence(sentence)
    {:noreply, %{pid: pid, port_name: port_name, data: ""}}
  end

  def handle_info({:nerves_uart, port_name, data}, %{pid: pid, port_name: port_name, data: old_data}) do
    {:noreply, %{pid: pid, port_name: port_name, data: old_data <> data}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, %{pid: pid, port_name: _port_name}) do
    Nerves.UART.close(pid)
    Nerves.UART.stop(pid)
  end
end
