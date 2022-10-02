import Config

#config :xgps, port_to_start: {"/dev/ttyUSB0", "AdafruitGps"}
#config :xgps, port_to_start: {:simulate, "simulator_positions.txt"}
config :xgps, port_to_start: {:simulate}

config :logger, level: :info
