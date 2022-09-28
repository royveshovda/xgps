defmodule XGPS.Driver.State do
  defstruct [
    gps_data: nil,
    pid: nil,
    port_name: nil,
    mod: nil
  ]
end
