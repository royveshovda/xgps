defmodule XGPS.Driver.PMTK do
  @moduledoc """
  XGPS driver for PMTK GPS-types (like Adafruit GPS)
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
        cmd1 = "$PMTK313,1*2E\r\n" # enable SBAS
        cmd2 = "$PMTK319,1*24\r\n" # Set SBAS to not test mode
        cmd3 = "$PMTK301,2*2E\r\n" # Enable SBAS to be used for DGPS
        cmd4 = "$PMTK286,1*23\r\n" # Enable AIC (anti-inteference)
        cmd5 = "$PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*28\r\n" # Output only RMC & GGA
        cmd6 = "$PMTK397,0*23\r\n" # Disable nav-speed threshold
        UART.write(pid, cmd1)
        UART.write(pid, cmd2)
        UART.write(pid, cmd3)
        UART.write(pid, cmd4)
        UART.write(pid, cmd5)
        UART.write(pid, cmd6)

        {:ok, state}
      end
  end
end
