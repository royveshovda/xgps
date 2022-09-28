defmodule XGPS.Example.Consumer do
  @moduledoc """
  The GenEvent handler implementation is a simple consumer.
  """
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  # Callbacks

  def init(:ok) do
    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.
    {:consumer, :ok, subscribe_to: [XGPS.Broadcaster]}
  end

  @doc """
  This function will be called once for each report from the GPS.
  """
  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect {self(), event}
    end
    {:noreply, [], state}
  end
end
