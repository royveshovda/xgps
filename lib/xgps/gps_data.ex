defmodule XGPS.GpsData do
  defstruct [
    has_fix: false,
    time: nil,
    date: nil,
    latitude: nil,
    longitude: nil,
    geoidheight: nil,
    altitude: nil,
    speed: nil,
    angle: nil,
    magvariation: nil,
    hdop: nil,
    fix_quality: nil,
    satelites: nil
  ]
end
