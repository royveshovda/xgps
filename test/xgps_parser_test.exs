defmodule XGPSParserTest do
  use ExUnit.Case

  # VTG: OK
  # RMC: ?
  # GGA: ?
  # GSV: OK
  # GSA: OK
  # PGTOP: OK
  # PGACK: OK

  test "parse sentence RMC" do
    sentence = "$GPRMC,144728.000,A,5441.1600,N,02515.6000,E,1.37,38.57,190716,,,A*50"
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
                  magnetic_variation: nil,
                  unknown: nil,
                  autonomous: "A"
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence RMC - wrong content length" do
    sentence = "$GPRMC,144728.000,A,5441.3992,N,02515.6704,E,1.37,38.57,190716,A*55"
    expected = {:unknown, :unknown_content_length}
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence GGA" do
    sentence = "$GPGGA,144729.000,5441.1600,S,02515.6000,W,1,05,2.20,118.7,M,27.6,M,,*61"
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
                  unknown_1: nil,
                  unknown_2: nil
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence GGA - wrong content length" do
    sentence = "$GPGGA,144729.000,5441.3996,N,02515.6709,E,1,05,2.20,118.7,M,27.6,M*62"
    expected = {:unknown, :unknown_content_length}
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence PGTOP" do
    sentence = "$PGTOP,11,2*6E"
    expected = %XGPS.Messages.PGTOP{
                  unknown_number: 11,
                  antenna_type: 2
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence PGTOP - wrong content length" do
    sentence = "$PGTOP,11,2,,*6E"
    expected = {:unknown, :unknown_content_length}
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence PGACK" do
    sentence = "$PGACK,33,1*6F"
    expected = %XGPS.Messages.PGACK{
                  request1: "33",
                  request2: "1"
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence PGACK - wrong content length" do
    sentence = "$PGACK,33,1,,*6F"
    expected = {:unknown, :unknown_content_length}
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence VTG" do
    sentence = "$GPVTG,38.57,T,,M,1.37,N,2.53,K,A*05"
    expected = %XGPS.Messages.VTG{
                  true_track_made_good: 38.57,
                  magnetic_track_made_good: nil,
                  ground_speed_in_knots: 1.37,
                  ground_speed_in_km_h: 2.53,
                  autonomous: "A"
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence VTG - wrong content length" do
    sentence = "$GPVTG,38.57,T,,M,1.37,N,2.53,K,A,,*05"
    expected = {:unknown, :unknown_content_length}
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence GSA" do
    sentence = "$GPGSA,A,3,21,26,18,10,16,,,,,,,,2.41,2.20,0.99*0D"
    expected = %XGPS.Messages.GSA{
                  selection: "A",
                  fix_3d: 3,
                  prn_1_for_fix: 21,
                  prn_2_for_fix: 26,
                  prn_3_for_fix: 18,
                  prn_4_for_fix: 10,
                  prn_5_for_fix: 16,
                  prn_6_for_fix: nil,
                  prn_7_for_fix: nil,
                  prn_8_for_fix: nil,
                  prn_9_for_fix: nil,
                  prn_10_for_fix: nil,
                  prn_11_for_fix: nil,
                  prn_12_for_fix: nil,
                  pdop: 2.41,
                  hdop: 2.20,
                  vdop: 0.99
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence GSA - wrong content length" do
    sentence = "$GPGSA,A,3,21,26,18,10,16,,,,,,,,2.41,2.20,0.99,,*0D"
    expected = {:unknown, :unknown_content_length}
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence GSV" do
    sentence = "$GPGSV,3,2,12,10,40,181,22,26,32,206,25,20,27,053,,15,22,069,*7A"
    expected = %XGPS.Messages.GSV{
                  number_of_sences: 3,
                  sentence_number: 2,
                  number_of_satelites_in_view: 12,
                  satelite_prn_number: 10,
                  elevation_degrees: 40,
                  azimuth_degrees: 181,
                  sat_1_snr: 22,
                  sat_2_snr: 26,
                  sat_3_snr: 32,
                  sat_4_snr: 206,
                  sat_5_snr: 25,
                  sat_6_snr: 20,
                  sat_7_snr: 27,
                  sat_8_snr: 53,
                  sat_9_snr: nil,
                  sat_10_snr: 15,
                  sat_11_snr: 22,
                  sat_12_snr: 69,
                  autonomous: nil
                }
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end

  test "parse sentence GSV - wrong content length" do
    sentence = "$GPGSV,3,2,12,10,40,181,22,26,32,206,25,20,27,053,,15,22,069,,,*7A"
    expected = {:unknown, :unknown_content_length}
    actual = XGPS.Parser.parse_sentence(sentence)
    assert expected == actual
  end



  test "unwrap sentence - OK - 1" do
    sentence = "$GPRMC,144728.000,A,5441.3992,N,02515.6704,E,1.37,38.57,190716,,,A*55"
    expected = "GPRMC,144728.000,A,5441.3992,N,02515.6704,E,1.37,38.57,190716,,,A"
    {:ok, actual} = XGPS.Parser.unwrap_sentence(sentence)
    assert expected == actual
  end

  test "unwrap sentence - OK - 2" do
    sentence = "$GPGGA,144729.000,5441.3996,N,02515.6709,E,1,05,2.20,118.7,M,27.6,M,,*62"
    expected = "GPGGA,144729.000,5441.3996,N,02515.6709,E,1,05,2.20,118.7,M,27.6,M,,"
    {:ok, actual} = XGPS.Parser.unwrap_sentence(sentence)
    assert expected == actual
  end

  test "unwrap sentence - ERROR" do
    sentence = "$GPGGA,144729.000,5441.3996,N,02515.6709,E,1,05,2.20,118.7,M,27.6,M,,*26"
    expected = :checksum
    {:error, actual} = XGPS.Parser.unwrap_sentence(sentence)
    assert expected == actual
  end

  test "unwrap type GPGGA" do
    body = "GPGGA,144729.000,5441.3996,N,02515.6709,E,1,05,2.20,118.7,M,27.6,M,,"
    expected_type = :gga
    expected_content = ["144729.000","5441.3996","N","02515.6709","E","1","05","2.20","118.7","M","27.6","M", "", ""]
    {type, content} = XGPS.Parser.unwrap_type(body)
    assert expected_type == type
    assert expected_content == content
  end

  test "unwrap type GPRMC" do
    body = "GPRMC,144728.000,A,5441.3992,N,02515.6704,E,1.37,38.57,190716,,,A"
    expected_type = :rmc
    expected_content = ["144728.000","A","5441.3992","N","02515.6704","E","1.37","38.57","190716","","","A"]
    {type, content} = XGPS.Parser.unwrap_type(body)
    assert expected_type == type
    assert expected_content == content
  end

  test "unwrap type GPGSV" do
    body = "GPGSV,3,2,12,10,40,181,22,26,32,206,25,20,27,053,,15,22,069,"
    expected_type = :gsv
    expected_content = ["3","2","12","10","40","181","22","26","32","206","25","20","27","053","","15","22","069",""]
    {type, content} = XGPS.Parser.unwrap_type(body)
    assert expected_type == type
    assert expected_content == content
  end

  test "unwrap type GPGSA" do
    body = "GPGSA,A,3,21,26,18,10,16,,,,,,,,2.41,2.20,0.99"
    expected_type = :gsa
    expected_content = ["A","3","21","26","18","10","16","","","","","","","","2.41","2.20","0.99"]
    {type, content} = XGPS.Parser.unwrap_type(body)
    assert expected_type == type
    assert expected_content == content
  end

  test "unwrap type GPVTG" do
    body = "GPVTG,38.57,T,,M,1.37,N,2.53,K,A"
    expected_type = :vtg
    expected_content = ["38.57","T","","M","1.37","N","2.53","K","A"]
    {type, content} = XGPS.Parser.unwrap_type(body)
    assert expected_type == type
    assert expected_content == content
  end

  test "unwrap type PGTOP" do
    body = "PGTOP,11,2"
    expected_type = :pgtop
    expected_content = ["11","2"]
    {type, content} = XGPS.Parser.unwrap_type(body)
    assert expected_type == type
    assert expected_content == content
  end

  test "unwrap type PGACK" do
    body = "PGACK,33,1"
    expected_type = :pgack
    expected_content = ["33","1"]
    {type, content} = XGPS.Parser.unwrap_type(body)
    assert expected_type == type
    assert expected_content == content
  end

  test "unwrap unknown type" do
    body = "PGABC,33,1"
    expected_type = :unknown
    expected_content = ["PGABC","33","1"]
    {type, content} = XGPS.Parser.unwrap_type(body)
    assert expected_type == type
    assert expected_content == content
  end

  test "'CO' hex_string is 192" do
    hex_string = "C0"
    expected_int = 192
    actual = XGPS.Parser.hex_string_to_int(hex_string)
    assert expected_int == actual
  end

  test "192 is 'C0' hex_string" do
    expected_hex_string = "C0"
    int = 192
    actual = XGPS.Parser.int_to_hex_string(int)
    assert expected_hex_string == actual
  end

end
