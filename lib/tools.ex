defmodule XGPS.Tools do
  def hex_string_to_int(string) do
    string |> Base.decode16! |> :binary.decode_unsigned
  end

  def int_to_hex_string(int) do
    int |> :binary.encode_unsigned |> Base.encode16
  end
end
