defmodule XGPS.Driver.GP04S do
  @moduledoc """
  Driver for GP-04S GPS antenna
  """

  alias Circuits.UART

  def init(%{pid: pid, port_name: port_name} = state) do
    :ok = UART.configure(pid, framing: {UART.Framing.Line, separator: "\r\n"})
    :ok = UART.open(pid, port_name, speed: 4_800, active: true)

    {:ok, state}
  end
end
