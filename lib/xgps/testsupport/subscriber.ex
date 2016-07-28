alias Experimental.{GenStage}
defmodule XGPS.TestSupport.Subscriber do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def contains_timestamp?(timestamp) do
    res1 = GenStage.call(__MODULE__, {:any_timestamp, timestamp})
    case res1 do
      true -> true
      false ->
        Process.sleep(50)
        res2 =  GenStage.call(__MODULE__, {:any_timestamp, timestamp})
        case res2 do
          true -> true
          false ->
            Process.sleep(100)
            res3 =  GenStage.call(__MODULE__, {:any_timestamp, timestamp})
            case res3 do
              true -> true
              false ->
                Process.sleep(250)
                GenStage.call(__MODULE__, {:any_timestamp, timestamp})
            end
        end
    end
  end

  def has_one?(event) do
    Process.sleep(125)
    res1 = GenStage.call(__MODULE__, {:any_event, event})
    case res1 do
      true -> true
      false ->
        Process.sleep(250)
        res2 =  GenStage.call(__MODULE__, {:any_event, event})
        case res2 do
          true -> true
          false ->
            Process.sleep(500)
            res3 =  GenStage.call(__MODULE__, {:any_event, event})
            case res3 do
              true -> true
              false ->
                Process.sleep(1000)
                GenStage.call(__MODULE__, {:any_event, event})
            end
        end
    end
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
end
