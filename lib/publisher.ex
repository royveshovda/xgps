defmodule XGPS.Publisher do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    # TODO: Init GenEvent stuff here
    {:ok, %{}}
  end

end
