defmodule XGPS.Port.Simulator do
  use GenServer

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  defmodule State do
    defstruct [
      file_name: nil,
      positions: nil,
      next_position_index: nil,
      parent_pid: nil
      ]
  end

  ###
  ### Callbacks
  ###
  def init({file_name, parent_pid}) do
    {:ok, content} = File.read(file_name)
    positions =
      content
      |> String.split(["\n", "\r\n"])
      |> Enum.filter(&(not String.starts_with?(&1,"#")))
      |> Enum.filter(&(String.length(&1) > 0))
      |> Enum.map(&(String.split(&1, ",")))
      |> Enum.map(&(parse_line(&1)))

    state = %State{file_name: file_name, positions: positions, next_position_index: 0, parent_pid: parent_pid}
    Process.send_after(self(), :send_position, 1000)
    Logger.info("Simulator running with initial state: #{inspect state}")
    {:ok, state}
  end

  def handle_info(:send_position, %State{positions: positions, next_position_index: idx, parent_pid: parent_pid} = state) do
    pos = Enum.at(positions, idx)

    send_position(parent_pid, pos)
    next_idx = rem(idx+1, length(positions))
    Process.send_after(self(), :send_position, 1000)
    {:noreply, %{state | next_position_index: next_idx}}
  end

  ###
  ### Priv
  ###
  defp send_position(parent_pid, {lat, lon, alt}) do
    time = NaiveDateTime.utc_now()
    send_position(parent_pid, {lat, lon, alt, time})
  end

  defp send_position(parent_pid, {lat, lon, alt, time}) do
    Logger.debug("Sending: #{lat}, #{lon} -- #{time}")
    XGPS.Port.Supervisor.send_simulated_position(parent_pid, lat, lon, alt, time)
    :ok
  end

  defp parse_line(line_pieces) do
    pieces = Enum.map(line_pieces, &(String.trim(&1)))
    parse_line_pieces(pieces)
  end

  defp parse_line_pieces([lat_s, lon_s, alt_s]) do
    {lat, _} = Float.parse(lat_s)
    {lon, _} = Float.parse(lon_s)
    {alt, _} = Float.parse(alt_s)
    {lat, lon, alt}
  end

  defp parse_line_pieces([lat_s, lon_s, alt_s, timestamp_s]) do
    {lat, _} = Float.parse(lat_s)
    {lon, _} = Float.parse(lon_s)
    {alt, _} = Float.parse(alt_s)
    {:ok, timestamp} = NaiveDateTime.from_iso8601(timestamp_s)
    {lat, lon, alt, timestamp}
  end
end
