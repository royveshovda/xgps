use Mix.Config

port_to_start =
  with {:ok, port} <- System.fetch_env("XGPS_PORT"),
       {:ok, driver} <- System.fetch_env("XGPS_DRIVER") do
    {port, driver}
  else
    _ ->
      nil
  end

config :xgps, port_to_start: port_to_start

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env()}.exs"
