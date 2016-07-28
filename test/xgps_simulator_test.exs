defmodule XGPSSimulatorTest do
  use ExUnit.Case, async: false
  # Does have to be run separate from others using the :simulate port.
  # Also important to slose the :simulate port after completion

  setup do
    {:ok, _pid} = XGPS.Ports.start_port(:simulate)
    on_exit fn ->
      :ok = XGPS.Ports.stop_port(:simulate)
    end
    :ok
  end

  test "Simulator: send one simulated position" do
    lat = 1.234
    lon = 5.678
    alt = 11.22

    XGPS.Ports.send_simulated_position(lat, lon, alt)
    {:ok, gps} = XGPS.Ports.get_one_position()
    assert true == gps.has_fix
    assert lat == gps.latitude
    assert lon == gps.longitude
    assert {alt, :meter} == gps.altitude
  end

  test "Simulator: send one simulated position - no fix" do
    XGPS.Ports.send_simulated_no_fix()
    {:ok, gps} = XGPS.Ports.get_one_position()

    assert false == gps.has_fix
  end

  test "Simulator: send one simulated position - with date_time" do
    lat = 1.234
    lon = 5.678
    alt = 11.22
    {:ok, date_time} = NaiveDateTime.new(2016,07,26, 10, 11, 12, {0,6})

    XGPS.Ports.send_simulated_position(lat, lon, alt, date_time)
    {:ok, gps} = XGPS.Ports.get_one_position()
    assert true == gps.has_fix
    assert lat == gps.latitude
    assert lon == gps.longitude
    assert {alt, :meter} == gps.altitude
    assert NaiveDateTime.to_date(date_time) == gps.date
    assert NaiveDateTime.to_time(date_time) == gps.time
  end

  test "Simulator: send one simulated position - no fix - with date_time" do
    {:ok, date_time} = NaiveDateTime.new(2016,07,26, 10, 11, 12, {0,6})

    XGPS.Ports.send_simulated_no_fix(date_time)
    {:ok, gps} = XGPS.Ports.get_one_position()

    assert false == gps.has_fix
    assert NaiveDateTime.to_date(date_time) == gps.date
    assert NaiveDateTime.to_time(date_time) == gps.time
  end
end
