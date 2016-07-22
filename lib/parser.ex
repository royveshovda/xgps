defmodule XGPS.Parser do
  require Bitwise

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
  defp get_type(["GPGSV"|content]), do: {:gsv, content}
  defp get_type(["GPGSA"|content]), do: {:gsa, content}
  defp get_type(["GPVTG"|content]), do: {:vtg, content}
  defp get_type(["PGTOP"|content]), do: {:pgtop, content}
  defp get_type(["PGACK"|content]), do: {:pgack, content}
  defp get_type(content), do: {:unknown, content}

  defp parse_content({:rmc, content}) do
    case length(content) do
      12 ->
        %XGPS.Messages.RMC{
          time: parse_time(Enum.at(content, 0)),
          status: Enum.at(content, 1) |> parse_string,
          latitude: Enum.at(content, 2)<>","<>Enum.at(content, 3),
          longitude: Enum.at(content, 4)<>","<>Enum.at(content, 5),
          speed_over_groud: parse_float(Enum.at(content, 6)),
          track_angle: parse_float(Enum.at(content, 7)),
          date: Enum.at(content, 8) |> parse_date,
          magnetic_variation: parse_float(Enum.at(content, 9)),
          unknown: Enum.at(content, 10) |> parse_string,
          autonomous: Enum.at(content, 11) |> parse_string
        }
      _ -> {:unknown, :unknown_content_length}
    end
  end

  defp parse_content({:gga, content}) do
    case length(content) do
      14 ->
        %XGPS.Messages.GGA{
          fix_taken: parse_time(Enum.at(content, 0)),
          latitude: Enum.at(content, 1)<>","<>Enum.at(content, 2),
          longitude: Enum.at(content, 3)<>","<>Enum.at(content, 4),
          fix_quality: parse_int(Enum.at(content, 5)),
          number_of_satelites_tracked: parse_int(Enum.at(content, 6)),
          horizontal_dilution: parse_float(Enum.at(content, 7)),
          altitude: {parse_float(Enum.at(content, 8)), parse_metric(Enum.at(content, 9))},
          height_over_goeid: {parse_float(Enum.at(content, 10)), parse_metric(Enum.at(content, 11))},
          unknown_1: Enum.at(content, 12) |> parse_string,
          unknown_2: Enum.at(content, 13) |> parse_string
        }
      _ -> {:unknown, :unknown_content_length}
    end
  end

  defp parse_content({:gsv, content}) do
    case length(content) do
      19 ->
        %XGPS.Messages.GSV{
          number_of_sences: parse_int(Enum.at(content, 0)),
          sentence_number: parse_int(Enum.at(content, 1)),
          number_of_satelites_in_view: parse_int(Enum.at(content, 2)),
          satelite_prn_number: parse_int(Enum.at(content, 3)),
          elevation_degrees: parse_int(Enum.at(content, 4)),
          azimuth_degrees: parse_int(Enum.at(content, 5)),
          sat_1_snr: parse_int(Enum.at(content, 6)),
          sat_2_snr: parse_int(Enum.at(content, 7)),
          sat_3_snr: parse_int(Enum.at(content, 8)),
          sat_4_snr: parse_int(Enum.at(content, 9)),
          sat_5_snr: parse_int(Enum.at(content, 10)),
          sat_6_snr: parse_int(Enum.at(content, 11)),
          sat_7_snr: parse_int(Enum.at(content, 12)),
          sat_8_snr: parse_int(Enum.at(content, 13)),
          sat_9_snr: parse_int(Enum.at(content, 14)),
          sat_10_snr: parse_int(Enum.at(content, 15)),
          sat_11_snr: parse_int(Enum.at(content, 16)),
          sat_12_snr: parse_int(Enum.at(content, 17)),
          autonomous: Enum.at(content, 18) |> parse_string
        }
      _ -> {:unknown, :unknown_content_length}
    end
  end

  defp parse_content({:gsa, content}) do
    case length(content) do
      17 ->
        %XGPS.Messages.GSA{
          selection: Enum.at(content,0) |> parse_string,
          fix_3d: parse_int(Enum.at(content,1)),
          prn_1_for_fix: parse_int(Enum.at(content,2)),
          prn_2_for_fix: parse_int(Enum.at(content,3)),
          prn_3_for_fix: parse_int(Enum.at(content,4)),
          prn_4_for_fix: parse_int(Enum.at(content,5)),
          prn_5_for_fix: parse_int(Enum.at(content,6)),
          prn_6_for_fix: parse_int(Enum.at(content,7)),
          prn_7_for_fix: parse_int(Enum.at(content,8)),
          prn_8_for_fix: parse_int(Enum.at(content,9)),
          prn_9_for_fix: parse_int(Enum.at(content,10)),
          prn_10_for_fix: parse_int(Enum.at(content,11)),
          prn_11_for_fix: parse_int(Enum.at(content,12)),
          prn_12_for_fix: parse_int(Enum.at(content,13)),
          pdop: parse_float(Enum.at(content,14)),
          hdop: parse_float(Enum.at(content,15)),
          vdop: parse_float(Enum.at(content,16))
        }
      _ -> {:unknown, :unknown_content_length}
    end
  end

  defp parse_content({:vtg, content}) do
    case length(content) do
      9 ->
        %XGPS.Messages.VTG{
          true_track_made_good: parse_float(Enum.at(content, 0)),
          magnetic_track_made_good: parse_float(Enum.at(content, 2)),
          ground_speed_in_knots: parse_float(Enum.at(content, 4)),
          ground_speed_in_km_h: parse_float(Enum.at(content, 6)),
          autonomous: Enum.at(content, 8) |> parse_string
        }
      _ -> {:unknown, :unknown_content_length}
    end
  end

  defp parse_content({:pgtop, content}) do
    case length(content) do
      2 ->
        %XGPS.Messages.PGTOP{
          unknown_number: parse_int(Enum.at(content, 0)),
          antenna_type: parse_int(Enum.at(content, 1))
        }
      _ -> {:unknown, :unknown_content_length}
    end
  end

  defp parse_content({:pgack, content}) do
    case length(content) do
      2 ->
        %XGPS.Messages.PGACK{
          request1: Enum.at(content, 0) |> parse_string,
          request2: Enum.at(content, 1) |> parse_string
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
end
