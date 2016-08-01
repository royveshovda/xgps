alias Experimental.{GenStage}
defmodule XGPS.Test.Subscriber do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def contains_timestamp?(timestamp) do
    func = fn -> GenStage.call(__MODULE__, {:any_timestamp, timestamp}) end
    try_with_fallback(func)
  end

  def has_one?(event) do
    func = fn -> GenStage.call(__MODULE__, {:any_event, event}) end
    try_with_fallback(func)
  end

  def init(:ok) do
    {:consumer, [], subscribe_to: [XGPS.Broadcaster]}
  end

  def handle_events(events, _from, all_events) do
    combined_events = all_events ++ events
    {:noreply, [], combined_events}
  end

  def handle_call({:any_timestamp, timestamp}, _from, all_events) do
    result = Enum.any?(all_events, fn(event) -> event.time == timestamp end)
    {:reply, result, [], all_events}
  end

  def handle_call({:any_event, event}, _from, all_events) do
    result = Enum.any?(all_events, fn(e) -> e == event end)
    {:reply, result, [], all_events}
  end

  defp try_with_fallback(func) do
    Process.sleep(25)
    res1 = func.()
    case res1 do
      true -> true
      false ->
        Process.sleep(50)
        res2 =  func.()
        case res2 do
          true -> true
          false ->
            Process.sleep(100)
            res3 =  func.()
            case res3 do
              true -> true
              false ->
                Process.sleep(200)
                func.()
            end
        end
    end
  end
end
