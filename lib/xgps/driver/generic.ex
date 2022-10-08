defmodule XGPS.Driver.Generic do
  @moduledoc """
  Generic driver for XGPS
  """

  require Logger

  alias Circuits.UART

  def init(%{pid: pid, port_name: port_name, speed: speed} = state) do
    :ok = UART.configure(pid, framing: {UART.Framing.Line, separator: "\r\n"})
    case UART.open(pid, port_name, speed: speed, active: true) do
      {:error, :enoent} ->
        Logger.error("Could not find UART port")
        :error
      {:error, :eagain} ->
        Logger.error("UART port already open")
        :error
      {:error, :eacces} ->
        Logger.error("No access to UART port")
        :error
      :ok ->
        {:ok, state}
      end
  end
end
