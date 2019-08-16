defmodule XGPS.Broadcaster do
  @moduledoc """
  Heavily inspired (almost a copy) from the GenEvent-replacement example from GenStage-repo at:
  https://github.com/elixir-lang/gen_stage
  """
   use GenStage

   @doc """
  Starts the broadcaster.
  """
  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Sends an event async.
  """
  def async_notify(event) do
    GenStage.cast(__MODULE__, {:notify, event})
  end

  ## Callbacks

  def init(:ok) do
    {:producer, {:queue.new, 0, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_cancel(_, _, {queue, demand, number_of_subscribers}) do
    {:noreply, [], {queue, demand, number_of_subscribers - 1}}
  end

  def handle_subscribe(_, _ ,_ ,{queue, demand, number_of_subscribers}) do
    {:automatic, {queue, demand, number_of_subscribers + 1}}
  end

  def handle_cast({:notify, _event}, {_queue, _demand, 0}) do
    {:noreply, [], {:queue.new, 0, 0}}
  end

  def handle_cast({:notify, event}, {queue, demand, number_of_subscribers}) do
    dispatch_events(:queue.in(event, queue), demand, [], number_of_subscribers)
  end

  def handle_demand(incoming_demand, {queue, demand, number_of_subscribers}) do
    dispatch_events(queue, incoming_demand + demand, [], number_of_subscribers)
  end

  # TODO: Make sure the queue does not grow too big
  defp dispatch_events(queue, demand, events, number_of_subscribers) do
    with d when d > 0 <- demand,
         {{:value, event}, queue} <- :queue.out(queue) do
      dispatch_events(queue, demand - 1, [event | events], number_of_subscribers)
    else
      _ -> {:noreply, Enum.reverse(events), {queue, demand, number_of_subscribers}}
    end
  end
end
