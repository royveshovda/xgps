defmodule XGPS.Tools do
  def hex_string_to_int(string) do
    string |> Base.decode16! |> :binary.decode_unsigned
  end

  def int_to_hex_string(int) do
    int |> :binary.encode_unsigned |> Base.encode16
  end

  def lat_to_decimal_degrees(degrees, minutes, "N"), do: degrees + (minutes/60.0)
  def lat_to_decimal_degrees(degrees, minutes, "S"), do: (degrees + (minutes/60.0)) * (-1.0)
  def lon_to_decimal_degrees(degrees, minutes, "E"), do: degrees + (minutes/60.0)
  def lon_to_decimal_degrees(degrees, minutes, "W"), do: (degrees + (minutes/60.0)) * (-1.0)

  def  lat_from_decimal_degrees(decimal_degrees) when decimal_degrees >= 0.0 do
    degrees = Float.floor(decimal_degrees)
    minutes = (decimal_degrees - degrees) * 60.0
    bearing = "N"
    {degrees, minutes, bearing}
  end

  def  lat_from_decimal_degrees(decimal_degrees) when decimal_degrees < 0.0 do
    degrees = Float.ceil(decimal_degrees) * (-1.0)
    minutes = (decimal_degrees + degrees) * -60.0
    bearing = "S"
    {degrees, minutes, bearing}
  end

  def  lon_from_decimal_degrees(decimal_degrees) when decimal_degrees >= 0.0 do
    degrees = Float.floor(decimal_degrees)
    minutes = (decimal_degrees - degrees) * 60.0
    bearing = "E"
    {degrees, minutes, bearing}
  end

  def  lon_from_decimal_degrees(decimal_degrees) when decimal_degrees < 0.0 do
    degrees = Float.ceil(decimal_degrees) * (-1.0)
    minutes = (decimal_degrees + degrees) * -60.0
    bearing = "W"
    {degrees, minutes, bearing}
  end


end
