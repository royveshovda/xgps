defmodule XGPS.Driver.Generic do
  @moduledoc """
  Generic driver for XGPS
  """

  alias Circuits.UART

  def init(%{pid: pid, port_name: port_name, speed: speed} = state) do
    :ok = UART.configure(pid, framing: {UART.Framing.Line, separator: "\r\n"})
    :ok = UART.open(pid, port_name, speed: speed, active: true)

    {:ok, state}
  end
end
