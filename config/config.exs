import Config
#config :xgps, port_to_start: {"/dev/serial0", :init_adafruit_gps}
#config :xgps, port_to_start: {:simulate,}


port_to_start =
  with {:ok, port} <- System.fetch_env("XGPS_PORT"),
       {:ok, driver} <- System.fetch_env("XGPS_DRIVER") do
    {port, driver}
  else
    _ ->
      nil
  end

config :xgps, port_to_start: port_to_start

import_config "#{Mix.env}.exs"
