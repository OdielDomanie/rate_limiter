defmodule RateLimiter do
  @moduledoc """
  Documentation for `RateLimiter`.
  """

  use GenServer

  @doc """
  Start a rate limit server under the rate_limit app's supervisor.
  """
  def start(opts) do
    DynamicSupervisor.start_child(
      RateLimiter.Supervisor,
      {__MODULE__, opts}
    )
  end

  def rate_limit(server, timeout \\ :infinity) do
      GenServer.call(server, :get_token, timeout)
  end

  def start_link(name: name, cap: cap, duration: duration) do
    GenServer.start_link(__MODULE__, %{cap: cap, duration: duration}, name: name)
  end

  @impl true
  def init(init_arg) do
    state =
      init_arg
      |> Map.put(:queue, :queue.new())
      |> Map.put(:len, 0)

    {:ok, state}
  end

  defp now, do: System.monotonic_time(:millisecond)

  @impl true
  def handle_call(
        :get_token,
        _from,
        %{cap: cap, duration: dur, queue: queue, len: len} = state
      ) do
    if len < cap do
      {:reply, :ok, %{state | len: len + 1, queue: :queue.in(now(), queue)}}
    else
      {{:value, ts}, queue} = :queue.out(queue)
      wait = dur - (now() - ts)

      if 0 < wait do
        :timer.sleep(wait)
      end

      {:reply, :ok, %{state | queue: :queue.in(now(), queue)}}
    end
  end
end
