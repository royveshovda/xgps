# Breaking changes for 1.0
Config API has been rewritten to use Keyword list instead of tuples. This will allow for more flexible config API for future extensions.

## Valid config

```elixir
config :xgps, port_to_start: [port_name: "/dev/ttyUSB0", driver: "PMTK", speed: 9600]
```

Where only `port_name` is mandatory. Default values:
- `driver`: "Generic"
- `speed`: 9600

Valid config for simulation is:

```elixir
config :xgps, port_to_start: [port_name: :simulate, file_name: "simulator_positions.txt"]
```

You can skip the `file_name` parameter if you want to control the positions sent (for example for testing scenarios).

## Not valid anymore

These config variants needs to be updated

### Variant 1

Not valid:

```elixir
config :xgps, port_to_start: {"dev/ttyUSB0", :init_adafruit_gps}
```

Will have to change to:

```elixir
config :xgps, port_to_start: [port_name: "/dev/ttyUSB0", driver: "PMTK"]
```

### Variant 2

Not valid:

```elixir
config :xgps, port_to_start: {"dev/ttyUSB0", "GP04S"}
```

Will have to change to:

```elixir
config :xgps, port_to_start: [port_name: "/dev/ttyUSB0", driver: "Generic", speed: 4800]
```