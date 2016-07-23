defmodule XGPS.EventManager do
  @name :xgps_event_manager

  def child_spec, do: Supervisor.Spec.worker(GenEvent, [[name: @name]])

  @doc """
  Notifies the event manager with an event of the form {:update, gps_data}
  """
  def update(gps_data), do: GenEvent.notify(@name, {:gps, gps_data})

  def register(handler, args), do: GenEvent.add_handler(@name, handler, args)
end
