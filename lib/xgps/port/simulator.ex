defmodule XGPS.Port.Simulator do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  defmodule State do
    defstruct [
      file_name: nil,
      positions: nil,
      next_position_index: nil
      ]
  end

  def init({file_name}) do
    {:ok, content} = File.read(file_name)
    positions =
      content
      |> String.split(["\n", "\r\n"])
      |> Enum.filter(&(not String.starts_with?(&1,"#")))
      |> Enum.filter(&(String.length(&1) > 0))
      |> Enum.map(&(String.split(&1, ",")))
      |> Enum.map(&(parse_line(&1)))

    state = %State{file_name: file_name, positions: positions, next_position_index: 0}
    Process.send_after(self(), :send_position, 1000)
    IO.puts "Simulator running with initial state: #{inspect state}"
    {:ok, state}
  end

  def handle_info(:send_position, %State{positions: positions, next_position_index: idx} = state) do
    #pos = Enum.at(positions, idx)
    #IO.inspect pos
    # TODO: Get position of supervisor

    next_idx =
      case idx >= (length(positions) - 1) do
        true -> 0
        false -> idx + 1
      end
    Process.send_after(self(), :send_position, 1000)
    {:noreply, %{state | next_position_index: next_idx}}
  end

  defp parse_line(line_pieces) do
    pieces = Enum.map(line_pieces, &(String.trim(&1)))
    parse_line_pieces(pieces)
  end

  defp parse_line_pieces([lat_s, lon_s]) do
    {lat, _} = Float.parse(lat_s)
    {lon, _} = Float.parse(lon_s)
    {lat, lon}
  end

  defp parse_line_pieces([lat_s, lon_s, timestamp_s]) do
    {lat, _} = Float.parse(lat_s)
    {lon, _} = Float.parse(lon_s)
    {:ok, timestamp} = NaiveDateTime.from_iso8601(timestamp_s)
    {lat, lon, timestamp}
  end
end
