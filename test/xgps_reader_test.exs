defmodule XGPSReaderTest do
  use ExUnit.Case, async: false
  # Does have to be run separate from others using the :simulate port.
  # Also important to slose the :simulate port after completion

  setup_all do
    {:ok, _pid} = XGPS.Ports.start_port(:simulate)
    {:ok, _pid2} = XGPS.TestSupport.Subscriber.start_link()
    on_exit fn ->
      :ok = XGPS.Ports.stop_port(:simulate)
    end
    :ok
  end

  setup do
    XGPS.Ports.reset_simulated_port_state()
  end

  test "valid sentence - send whole at once" do
    send_data("$GPRMC,112233.000,A,5441.1600,N,02515.6000,E,1.37,38.57,190716,,,A*5C\r\n")
    {:ok, expected_time} = Time.new(11,22,33, {0,6})
    assert XGPS.TestSupport.Subscriber.contains_timestamp?(expected_time)
  end

  test "valid sentence - send \n separately" do
    send_data("$GPRMC,112244.000,A,5441.1600,N,02515.6000,E,1.37,38.57,190716,,,A*5C\r")
    send_data("\n")
    {:ok, expected_time} = Time.new(11,22,44, {0,6})
    assert XGPS.TestSupport.Subscriber.contains_timestamp?(expected_time)
  end

  test "sentence with noise before - send whole at once" do
    send_data("noise$GPRMC,221111.000,A,5441.1600,N,02515.6000,E,1.37,38.57,190716,,,A*5C\r\n")
    {:ok, expected_time} = Time.new(22,11,11, {0,6})
    assert XGPS.TestSupport.Subscriber.contains_timestamp?(expected_time)
  end

  test "sentence with noise before - send \n separately" do
    send_data("noise$GPRMC,221155.000,A,5441.1600,N,02515.6000,E,1.37,38.57,190716,,,A*5C\r")
    send_data("\n")
    {:ok, expected_time} = Time.new(22,11,55, {0,6})
    assert XGPS.TestSupport.Subscriber.contains_timestamp?(expected_time)
  end

  test "sentence with noise after" do
    send_data("$GPRMC,223344.000,A,5441.1600,N,02515.6000,E,1.37,38.57,190716,,,A*5C\r\nnoise")
    {:ok, expected_time} = Time.new(22,33,44, {0,6})
    assert XGPS.TestSupport.Subscriber.contains_timestamp?(expected_time)
  end

  test "sentence with noise before and after" do
    send_data("noise$GPRMC,014455.000,A,5441.1600,N,02515.6000,E,1.37,38.57,190716,,,A*5D\r\nmorenoise")
    {:ok, expected_time} = Time.new(01,44,55, {0,6})
    assert XGPS.TestSupport.Subscriber.contains_timestamp?(expected_time)
  end

  defp send_data(data) do
    sim_pid = get_simulator
    [{_, reader_pid, _, _}] = Supervisor.which_children(sim_pid)
    send reader_pid, {:nerves_uart, :simulate, data}
  end

  defp get_simulator do
    Supervisor.which_children(XGPS.Ports)
    |> Enum.map(fn({_, pid, :supervisor, _}) -> pid end)
    |> Enum.map(fn(pid) -> {pid, XGPS.Port.Supervisor.get_port_name(pid)} end)
    |> Enum.filter(fn({_pid, port_name}) -> port_name == :simulate end)
    |> Enum.map(fn({pid, _port_name}) -> pid end)
    |> Enum.at(0)
  end
end
