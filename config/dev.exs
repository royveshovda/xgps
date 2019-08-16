use Mix.Config

config :logger, :level, :info

config :xgps, port_to_start: {"ttyUSB0", XGPS.Driver.GP04S}
