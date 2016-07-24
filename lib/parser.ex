defmodule XGPS.Parser do
  require Bitwise

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{}}
  end

  def parse_sentence(sentence) do
    case unwrap_sentence(sentence) do
      {:ok, body} ->
        body
        |> unwrap_type
        |> parse_content
      {:error, :checksum} ->
        {:error, :checksum}
    end
  end

  def unwrap_sentence(sentence) do
    {body, checksum} = split(sentence)
    calculated_checksum = calculate_checksum(body) |> int_to_hex_string
    case calculated_checksum == checksum do
      true -> {:ok, body}
      false -> {:error,:checksum}
    end
  end

  def unwrap_type(body) do
    parts = String.split(body, ",")
    get_type(parts)
  end

  defp split(sentence) do
    [main_raw, checksum] = String.split(sentence,"*",parts: 2)
    main = String.trim_leading(main_raw, "$")
    {main, checksum}
  end

  defp calculate_checksum text do
    Enum.reduce(String.codepoints(text), 0, &xor/2)
  end

  defp xor(x, acc) do
    <<val::utf8>> = x
    Bitwise.bxor(acc, val)
  end

  def hex_string_to_int(string) do
    string |> Base.decode16! |> :binary.decode_unsigned
  end

  def int_to_hex_string(int) do
    int |> :binary.encode_unsigned |> Base.encode16
  end

  defp get_type(["GPRMC"|content]), do: {:rmc, content}
  defp get_type(["GPGGA"|content]), do: {:gga, content}
  defp get_type(content), do: {:unknown, content}

  defp parse_content({:rmc, content}) do
    case length(content) do
      12 ->
        %XGPS.Messages.RMC{
          time: parse_time(Enum.at(content, 0)),
          status: Enum.at(content, 1) |> parse_string,
          latitude: parse_latitude(Enum.at(content, 2),Enum.at(content, 3)),
          longitude: parse_longitude(Enum.at(content, 4),Enum.at(content, 5)),
          speed_over_groud: parse_float(Enum.at(content, 6)),
          track_angle: parse_float(Enum.at(content, 7)),
          date: Enum.at(content, 8) |> parse_date,
          magnetic_variation: parse_float(Enum.at(content, 9))
        }
      _ -> {:unknown, :unknown_content_length}
    end
  end

  defp parse_content({:gga, content}) do
    case length(content) do
      14 ->
        %XGPS.Messages.GGA{
          fix_taken: parse_time(Enum.at(content, 0)),
          latitude: parse_latitude(Enum.at(content, 1),Enum.at(content, 2)),
          longitude: parse_longitude(Enum.at(content, 3),Enum.at(content, 4)),
          fix_quality: parse_int(Enum.at(content, 5)),
          number_of_satelites_tracked: parse_int(Enum.at(content, 6)),
          horizontal_dilution: parse_float(Enum.at(content, 7)),
          altitude: {parse_float(Enum.at(content, 8)), parse_metric(Enum.at(content, 9))},
          height_over_goeid: {parse_float(Enum.at(content, 10)), parse_metric(Enum.at(content, 11))},
          time_since_last_dgps: Enum.at(content, 12) |> parse_string,
          dgps_station_id: Enum.at(content, 13) |> parse_string
        }
      _ -> {:unknown, :unknown_content_length}
    end
  end

  defp parse_content({:unknown, content}) do
    {:unknown, content}
  end

  defp parse_float(""), do: nil
  defp parse_float(value) do
    {float, _} = Float.parse(value)
    float
  end

  defp parse_int(""), do: nil
  defp parse_int(value) do
    {integer, _} = Integer.parse(value)
    integer
  end

  defp parse_metric("M"), do: :meter
  defp parse_metric(_), do: :unknown

  defp parse_string(""), do: nil
  defp parse_string(value), do: value

  defp parse_time(time) when length(time) < 6, do: nil
  defp parse_time(time) do
    parts = String.split(time, ".")
    parse_hours_minutes_seconds_ms(parts)
  end

  defp parse_hours_minutes_seconds_ms([main]) when length(main) != 6, do: :unknown_format
  defp parse_hours_minutes_seconds_ms([main, _millis]) when length(main) != 6, do: :unknown_format
  defp parse_hours_minutes_seconds_ms([main, ""]), do: parse_hours_minutes_seconds_ms([main,"0"])
  defp parse_hours_minutes_seconds_ms([main]), do: parse_hours_minutes_seconds_ms([main,"0"])
  defp parse_hours_minutes_seconds_ms([main, millis]) do
    {ms,_} = Integer.parse(millis)
    {h,_} = Integer.parse(String.slice(main, 0, 2))
    {m,_} = Integer.parse(String.slice(main, 2, 2))
    {s,_} = Integer.parse(String.slice(main, 4, 2))
    {:ok, time} = Time.new(h,m,s,ms)
    time
  end

  defp parse_date(date_raw) when length(date_raw) != 6, do: :unknown_format
  defp parse_date(date_raw) do
    {day,_} = String.slice(date_raw,0,2) |> Integer.parse
    {month,_} = String.slice(date_raw,2,2) |> Integer.parse
    {year,_} = ("20" <> String.slice(date_raw, 4, 2)) |> Integer.parse
    {:ok, date} = Date.new(year, month, day)
    date
  end

  defp parse_latitude("", ""), do: nil

  defp parse_latitude(string, "N") do
    value = parse_latitude_degrees(string)
    value
  end

  defp parse_latitude(string, "S") do
    value = parse_latitude_degrees(string)
    value * (-1)
  end

  defp parse_latitude_degrees(string) do
    {deg, _} = String.slice(string,0,2) |> Float.parse
    {min, _} = String.slice(string,2,100) |> Float.parse
    deg + (min/60.0)
  end

  defp parse_longitude("", ""), do: nil

  defp parse_longitude(string, "E") do
    value = parse_longitude_degrees(string)
    value
  end

  defp parse_longitude(string, "W") do
    value = parse_longitude_degrees(string)
    value * (-1)
  end

  defp parse_longitude_degrees(string) do
    {deg, _} = String.slice(string,0,3) |> Float.parse
    {min, _} = String.slice(string,3,100) |> Float.parse
    deg + (min/60.0)
  end
end
