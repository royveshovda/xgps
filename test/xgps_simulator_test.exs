defmodule XGPSSimulatorTest do
  use ExUnit.Case

  test "Simulator: send one simulated position" do
    lat = 1.234
    lon = 5.678
    alt = 11.22
    XGPS.Ports_supervisor.start_port(:simulate)

    XGPS.Ports_supervisor.send_simulated_position(lat, lon, alt)
    {:ok, gps} = XGPS.Ports_supervisor.get_one_position()
    assert true == gps.has_fix
    assert lat == gps.latitude
    assert lon == gps.longitude
    assert {alt, :meter} == gps.altitude
  end

  test "Simulator: send one simulated position - no fix" do
    XGPS.Ports_supervisor.start_port(:simulate)

    XGPS.Ports_supervisor.send_simulated_no_fix()
    {:ok, gps} = XGPS.Ports_supervisor.get_one_position()

    assert false == gps.has_fix
  end

  test "Simulator: send one simulated position - with date_time" do
    lat = 1.234
    lon = 5.678
    alt = 11.22
    {:ok, date_time} = NaiveDateTime.new(2016,07,26, 10, 11, 12, {0,6})
    XGPS.Ports_supervisor.start_port(:simulate)

    XGPS.Ports_supervisor.send_simulated_position(lat, lon, alt, date_time)
    {:ok, gps} = XGPS.Ports_supervisor.get_one_position()
    assert true == gps.has_fix
    assert lat == gps.latitude
    assert lon == gps.longitude
    assert {alt, :meter} == gps.altitude
    assert NaiveDateTime.to_date(date_time) == gps.date
    assert NaiveDateTime.to_time(date_time) == gps.time
  end

  test "Simulator: send one simulated position - no fix - with date_time" do
    {:ok, date_time} = NaiveDateTime.new(2016,07,26, 10, 11, 12, {0,6})
    XGPS.Ports_supervisor.start_port(:simulate)

    XGPS.Ports_supervisor.send_simulated_no_fix(date_time)
    {:ok, gps} = XGPS.Ports_supervisor.get_one_position()

    assert false == gps.has_fix
    assert NaiveDateTime.to_date(date_time) == gps.date
    assert NaiveDateTime.to_time(date_time) == gps.time
  end
end
