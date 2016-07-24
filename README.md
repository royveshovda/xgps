# XGPS
[![Build Status](https://travis-ci.org/rveshovda/xgps.svg?branch=master)](https://travis-ci.org/rveshovda/xgps)
[![Hex version](https://img.shields.io/hexpm/v/xgps.svg "Hex version")](https://hex.pm/packages/xgps)

GPS for Elixir

XGPS runs as an application and will start along with you application, and connect to an serial port to get GPS data.

## TODO
- More documentation
- Consider GenStage

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `xgps` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:xgps, "~> 0.1.0"}]
    end
    ```

  2. Ensure `xgps` is started before your application:

    ```elixir
    def application do
      [applications: [:xgps]]
    end
    ```

## Usage 1: Get ask for position when you need one_for_one
This usage pattern is mostly for testing.
```{:ok, pid} = XGPS.Ports_supervisor.start_port("/dev/serial0")
XGPS.Port.Supervisor.get_gps_data(pid)
```

Pay attention to the has_fix if it is true or false. If has_fix=false, you cannot trust the other values.

## Usage 2: Get notified when new update
The most common usage pattern is to subscribe to the GenEvent publisher running
Check out the code inside the example-folder for an example for a subscriber. You need to implement identical code on you side to receive new positions.

## dependencies
To make an effort to be platform independent, XGPS uses [nerves_uart](https://github.com/nerves-project/nerves_uart) for the dirty details. Please make sure to follow the instructions for nerves_uart to make this compile and run on your system.

## Note
This application was tested on a Raspberry Pi using the AdaFruit Ultimate GPS ([1](https://www.adafruit.com/products/746), [2](https://www.adafruit.com/products/2324)), which essentially uses the chip MTK3339. Guarantees for other systems and chips cannot be given. But please provide feedback if working or not on other systems/chips.
