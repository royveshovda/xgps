defmodule XGPSToolsTest do
  use ExUnit.Case

  test "'CO' hex_string is 192" do
    hex_string = "C0"
    expected_int = 192
    actual = XGPS.Tools.hex_string_to_int(hex_string)
    assert expected_int == actual
  end

  test "192 is 'C0' hex_string" do
    expected_hex_string = "C0"
    int = 192
    actual = XGPS.Tools.int_to_hex_string(int)
    assert expected_hex_string == actual
  end
end
