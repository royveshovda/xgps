defmodule XGPS.Port.Simulator do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  defmodule State do
    defstruct [
      file_name: nil,
      positions: nil
      ]
  end

  def init(file_name) do
    # TODO: Open file
    state = %State{file_name: file_name, positions: []}
    IO.puts "Simulator running with initial state: #{inspect state}"
    {:ok, state}
  end

end
