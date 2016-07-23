defmodule XGPS.Demo.EventHandler do
  use GenEvent

  def handle_event({:gps, gps_data}, _) do
    IO.inspect gps_data
    {:ok, nil}
  end

  def register_with_manager do
    XGPS.EventManager.register(__MODULE__, nil)
  end

  def unregister_with_manager do
    XGPS.EventManager.unregister(__MODULE__, nil)
  end
end
