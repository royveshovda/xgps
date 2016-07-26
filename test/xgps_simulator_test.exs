defmodule XGPSSimulatorTest do
  use ExUnit.Case

  test "Simulator: send one simulated position" do
    lat = 1.234
    lon = 5.678
    alt = 11.22
    XGPS.Ports_supervisor.start_port(:simulate)

    XGPS.Ports_supervisor.send_simulated_position(lat, lon, alt)
    {:ok, gps} = XGPS.Ports_supervisor.get_one_position()

    assert lat == gps.latitude
    assert lon == gps.longitude
    assert {alt, :meter} == gps.altitude
  end

end
