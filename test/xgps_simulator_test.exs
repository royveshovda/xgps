defmodule XGPSSimulatorTest do
  use ExUnit.Case, async: false
  # Does have to be run separate from others using the :simulate port.
  # Also important to slose the :simulate port after completion

  setup_all do
    {:ok, _pid} = XGPS.Ports.start_port(:simulate)

    {:ok, _pid2} = XGPS.Test.Subscriber.start_link()
    on_exit fn ->
      :ok = XGPS.Ports.stop_port(:simulate)
    end
    :ok
  end

  setup do
    XGPS.Ports.reset_simulated_port_state()
  end

  test "Simulator: send one simulated position" do
    lat = 1.234
    lon = 5.678
    alt = 11.22
    {:ok, expected_time} = NaiveDateTime.new(2016,1,2,3,4,5, {0,6})
    expected_rmc = %XGPS.GpsData{
                        has_fix: false,
                        latitude: lat,
                        longitude: lon,
                        altitude: nil,
                        time: NaiveDateTime.to_time(expected_time),
                        date: NaiveDateTime.to_date(expected_time),
                        angle: 0.0,
                        fix_quality: nil,
                        speed: 0.0}

    expected_gga = %XGPS.GpsData{
                        has_fix: true,
                        latitude: lat,
                        longitude: lon,
                        altitude: {alt, :meter},
                        time: NaiveDateTime.to_time(expected_time),
                        date: NaiveDateTime.to_date(expected_time),
                        angle: 0.0,
                        fix_quality: 1,
                        speed: 0.0,
                        geoidheight: {0.0, :meter},
                        hdop: 0.0,
                        satelites: 5}


    XGPS.Ports.send_simulated_position(lat, lon, alt, expected_time)
    assert XGPS.Test.Subscriber.has_one?(expected_rmc)
    assert XGPS.Test.Subscriber.has_one?(expected_gga)
  end

  test "Simulator: send one simulated position - no fix - with date_time" do
    {:ok, expected_time} = NaiveDateTime.new(2016,02,3, 10, 11, 12, {0,6})

    expected_rmc = %XGPS.GpsData{
                        has_fix: false,
                        fix_quality: nil,
                        time: NaiveDateTime.to_time(expected_time),
                        date: NaiveDateTime.to_date(expected_time),
                        speed: 0.0}

    expected_gga = %XGPS.GpsData{
                        has_fix: false,
                        fix_quality: nil,
                        time: NaiveDateTime.to_time(expected_time),
                        date: NaiveDateTime.to_date(expected_time),
                        speed: 0.0}

    XGPS.Ports.send_simulated_no_fix(expected_time)
    assert XGPS.Test.Subscriber.has_one?(expected_rmc)
    assert XGPS.Test.Subscriber.has_one?(expected_gga)
  end
end
