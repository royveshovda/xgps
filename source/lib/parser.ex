defmodule XGPS.Parser do
  require Bitwise

  def parse_sentence(sentence) do
    case unwrap_sentence(sentence) do
      {:ok, body} ->
        {type, content} = unwrap_type(body)
        # TODO: Parse more
        {type, content}
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

  defp get_type(["GPRMC"|content]) do
    {:rmc, content}
  end

  defp get_type(["GPGGA"|content]) do
    {:gga, content}
  end

  defp get_type(["GPGSV"|content]) do
    {:gsv, content}
  end

  defp get_type(["GPGSA"|content]) do
    {:gsa, content}
  end

  defp get_type(["GPVTG"|content]) do
    {:vtg, content}
  end

  defp get_type(["PGTOP"|content]) do
    {:pgtop, content}
  end

  defp get_type(["PGACK"|content]) do
    {:pgack, content}
  end

  defp get_type(content) do
    {:unknown, content}
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




end
