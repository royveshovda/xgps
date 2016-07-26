defmodule XGPS.Tools do
  @moduledoc """
  Several different helper functions.
  """
  require Bitwise

  @doc """
  Will calculate and return a checksum defined for NMEA sentence.
  """
  def calculate_checksum text do
    Enum.reduce(String.codepoints(text), 0, &xor/2)
  end

  defp xor(x, acc) do
    <<val::utf8>> = x
    Bitwise.bxor(acc, val)
  end

  @doc """
  Converts from hex-string to int.
  ## Examples

      iex> XGPS.Tools.hex_string_to_int "C0"
      192

  """
  def hex_string_to_int(string) do
    string |> Base.decode16! |> :binary.decode_unsigned
  end

  @doc """
  Converts from int to hex-string.
  ## Examples

      iex> XGPS.Tools.int_to_hex_string 192
      "C0"

  """
  def int_to_hex_string(int) do
    int |> :binary.encode_unsigned |> Base.encode16
  end

  @doc """
  Converts latitude from degrees, minutes and bearing into decimal degrees
  ## Examples

      iex> XGPS.Tools.lat_to_decimal_degrees(54, 41.1600, "N")
      54.686

      iex> XGPS.Tools.lat_to_decimal_degrees(54, 41.1600, "S")
      -54.686

  """
  def lat_to_decimal_degrees(degrees, minutes, "N"), do: degrees + (minutes/60.0)
  def lat_to_decimal_degrees(degrees, minutes, "S"), do: (degrees + (minutes/60.0)) * (-1.0)

  @doc """
  Converts longitude from degrees, minutes and bearing into decimal degrees
  ## Examples

      iex> XGPS.Tools.lon_to_decimal_degrees(25, 15.6, "E")
      25.26

      iex> XGPS.Tools.lon_to_decimal_degrees(25, 15.6, "W")
      -25.26

  """
  def lon_to_decimal_degrees(degrees, minutes, "E"), do: degrees + (minutes/60.0)
  def lon_to_decimal_degrees(degrees, minutes, "W"), do: (degrees + (minutes/60.0)) * (-1.0)

  def  lat_from_decimal_degrees(decimal_degrees) when decimal_degrees >= 0.0 do
    degrees = Float.floor(decimal_degrees) |> round
    minutes = (decimal_degrees - degrees) * 60.0
    bearing = "N"
    {degrees, minutes, bearing}
  end

  @doc """
  Convert latitude from decimal degrees into degrees, minutes and bearing
  ## Examples

      iex> XGPS.Tools.lat_from_decimal_degrees(54.686)
      {54, 41.1600, "N"}

      iex> XGPS.Tools.lat_from_decimal_degrees(-54.686)
      {54, 41.1600, "S"}

  """
  def  lat_from_decimal_degrees(decimal_degrees) when decimal_degrees < 0.0 do
    degrees = Float.ceil(decimal_degrees) * (-1.0) |> round
    minutes = (decimal_degrees + degrees) * -60.0
    bearing = "S"
    {degrees, minutes, bearing}
  end

  @doc """
  Convert longitude from decimal degrees into degrees, minutes and bearing
  ## Examples

      XGPS.Tools.lon_from_decimal_degrees(25.26)
      {25, 15.6, "E"}

      XGPS.Tools.lon_from_decimal_degrees(-25.26)
      {25, 15.6, "W"}

  """
  def  lon_from_decimal_degrees(decimal_degrees) when decimal_degrees >= 0.0 do
    degrees = Float.floor(decimal_degrees) |> round
    minutes = (decimal_degrees - degrees) * 60.0
    bearing = "E"
    {degrees, minutes, bearing}
  end

  def  lon_from_decimal_degrees(decimal_degrees) when decimal_degrees < 0.0 do
    degrees = Float.ceil(decimal_degrees) * (-1.0) |> round
    minutes = (decimal_degrees + degrees) * -60.0
    bearing = "W"
    {degrees, minutes, bearing}
  end

  def to_gps_date(date) do
    year = "#{date.year}" |> String.slice(2,2)
    month = "#{date.month}" |> String.pad_leading(2,"0")
    day = "#{date.day}" |> String.pad_leading(2,"0")
    day <> month <> year
  end

  def to_gps_time(time) do
    hour = "#{time.hour}" |> String.pad_leading(2,"0")
    minute = "#{time.minute}" |> String.pad_leading(2,"0")
    second = "#{time.second}" |> String.pad_leading(2,"0")
    {micro, _} = time.microsecond
    ms = round(micro / 1000)
    millis = "#{ms}" |> String.pad_leading(3, "0")
    "#{hour}#{minute}#{second}." <> millis
  end

  def generate_rmc_and_gga_for_simulation(lat, lon, alt, date_time) do
    {lat_deg, lat_min, lat_bear} = XGPS.Tools.lat_from_decimal_degrees(lat)
    {lon_deg, lon_min, lon_bear} = XGPS.Tools.lon_from_decimal_degrees(lon)

    latitude = lat_to_string(lat_deg, lat_min, lat_bear)
    longitude = lon_to_string(lon_deg, lon_min, lon_bear)

    date = XGPS.Tools.to_gps_date(date_time)
    time = XGPS.Tools.to_gps_time(date_time)

    rmc_body = "GPRMC,#{time},A,#{latitude},#{longitude},0.0,0.0,#{date},,,A"
    rmc_checksum = XGPS.Tools.calculate_checksum(rmc_body) |> XGPS.Tools.int_to_hex_string
    rmc = "$#{rmc_body}*#{rmc_checksum}"
    gga_body = "GPGGA,#{time},#{latitude},#{longitude},1,05,0.0,#{alt},M,0.0,M,,"
    gga_checksum = XGPS.Tools.calculate_checksum(gga_body) |> XGPS.Tools.int_to_hex_string
    gga = "$#{gga_body}*#{gga_checksum}"
    {rmc, gga}
  end

  def generate_rmc_and_gga_for_simulation_no_fix(date_time) do
    date = XGPS.Tools.to_gps_date(date_time)
    time = XGPS.Tools.to_gps_time(date_time)
    rmc_body = "GPRMC,#{time},V,,,,,,,#{date},,,A"
    rmc_checksum = XGPS.Tools.calculate_checksum(rmc_body) |> XGPS.Tools.int_to_hex_string
    rmc = "$#{rmc_body}*#{rmc_checksum}"
    gga_body = "GPGGA,#{time},,,,,0,0,,,M,,M,,"
    gga_checksum = XGPS.Tools.calculate_checksum(gga_body) |> XGPS.Tools.int_to_hex_string
    gga = "$#{gga_body}*#{gga_checksum}"
    {rmc, gga}
  end

  defp lat_to_string(deg, min, bearing) when min >= 10.0 do
    deg_string = "#{deg}" |> String.pad_leading(2, "0")
    min_string = "#{Float.round(min,4)}" |> String.pad_trailing(7, "0")
    deg_string <> min_string <> "," <> bearing
  end

  defp lat_to_string(deg, min, bearing) do
    deg_string = "#{deg}" |> String.pad_leading(2, "0")
    min_string = "0#{Float.round(min,4)}" |> String.pad_trailing(7, "0")
    deg_string <> min_string <> "," <> bearing
  end

  defp lon_to_string(deg, min, bearing) when min > 10.0 do
    deg_string = "#{deg}" |> String.pad_leading(3, "0")
    min_string = "#{Float.round(min,4)}" |> String.pad_trailing(7, "0")
    deg_string <> min_string <> "," <> bearing
  end

  defp lon_to_string(deg, min, bearing) do
    deg_string = "#{deg}" |> String.pad_leading(3, "0")
    min_string = "0#{Float.round(min,4)}" |> String.pad_trailing(7, "0")
    deg_string <> min_string <> "," <> bearing
  end
end
