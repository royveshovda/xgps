defmodule XGPSParserTest do
  use ExUnit.Case

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
