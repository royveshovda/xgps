defmodule XGPSParserTest do
  use ExUnit.Case

  test "parse sentence GGA - no fix" do
    sentence = "$GPGGA,042940.000,,,,,0,05,,,M,,M,,*76\r\n"
    {:ok, time} = Time.new(4,29,40,000)
    expected = %XGPS.Messages.GGA{
                  fix_taken: time,
                  latitude: nil,
                  longitude: nil,
                  fix_quality: 0,
                  number_of_satelites_tracked: 5,
                  horizontal_dilution: nil,
                  altitude: {nil, :meter},
                  height_over_goeid: {nil, :meter},
                  time_since_last_dgps: nil,
                  dgps_station_id: nil
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence RMC" do
    sentence = "$GPRMC,144728.000,A,5441.1600,N,02515.6000,E,1.37,38.57,190716,,,A*50\r\n"
    {:ok, time} = Time.new(14,47,28,000)
    {:ok, date} = Date.new(2016,7,19)
    expected = %XGPS.Messages.RMC{
                  time: time,
                  status: "A",
                  latitude: 54.686,
                  longitude: 25.26,
                  speed_over_groud: 1.37,
                  track_angle: 38.57,
                  date: date,
                  magnetic_variation: nil
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence RMC - no fix" do
    sentence = "$GPRMC,144728.000,,,,,,,,190716,,,*51\r\n"
    {:ok, time} = Time.new(14,47,28,000)
    {:ok, date} = Date.new(2016,7,19)
    expected = %XGPS.Messages.RMC{
                  time: time,
                  status: nil,
                  latitude: nil,
                  longitude: nil,
                  speed_over_groud: nil,
                  track_angle: nil,
                  date: date,
                  magnetic_variation: nil
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence RMC - wrong content length" do
    sentence = "$GPRMC,144728.000,A,5441.3992,N,02515.6704,E,1.37,38.57,190716,A*55\r\n"
    expected = {:unknown, :unknown_content_length}
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence GGA" do
    sentence = "$GPGGA,144729.000,5441.1600,S,02515.6000,W,1,05,2.20,118.7,M,27.6,M,,*61\r\n"
    {:ok, time} = Time.new(14,47,29,000)
    expected = %XGPS.Messages.GGA{
                  fix_taken: time,
                  latitude: -54.686,
                  longitude: -25.26,
                  fix_quality: 1,
                  number_of_satelites_tracked: 5,
                  horizontal_dilution: 2.20,
                  altitude: {118.7, :meter},
                  height_over_goeid: {27.6, :meter},
                  time_since_last_dgps: nil,
                  dgps_station_id: nil
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence GGA - wrong content length" do
    sentence = "$GPGGA,144729.000,5441.3996,N,02515.6709,E,1,05,2.20,118.7,M,27.6,M*62\r\n"
    expected = {:unknown, :unknown_content_length}
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end
end
