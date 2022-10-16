defmodule XGPS.Driver.Generic do
  @moduledoc """
  Generic driver for XGPS
  """

  require Logger

  alias Circuits.UART

  def init(%{pid: pid, port_name: port_name, speed: speed} = state) do
    opts =
      case speed do
        nil ->
          [framing: {UART.Framing.Line, separator: "\r\n"}, active: true]
        _->
          [speed: speed, framing: {UART.Framing.Line, separator: "\r\n"}, active: true]
      end
    case UART.open(pid, port_name, opts) do
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
