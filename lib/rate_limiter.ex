defmodule RateLimiter do
  @moduledoc """
  Documentation for `RateLimiter`.
  """

  use GenServer

  @doc """
  Wait until the bucket opens. The RL server is started if not alive.

  `cap` and `duration` must match the values the RateLimiter server is started with.
  """
  def rate_limit(name, cap, duration, timeout \\ :infinity) do
    if !GenServer.whereis(name) do
      DynamicSupervisor.start_child(
        RateLimiter.Supervisor,
        {RateLimiter, name: name, cap: cap, duration: duration}
      )
    end

    GenServer.call(name, {:get_token, cap, duration}, timeout)
  end

  def start_link(name: name, cap: cap, duration: duration) do
    GenServer.start_link(__MODULE__, %{cap: cap, duration: duration}, name: name)
  end

  @impl true
  @doc false
  def init(init_arg) do
    state =
      init_arg
      |> Map.put(:queue, :queue.new())
      |> Map.put(:len, 0)

    {:ok, state}
  end

  defp now, do: System.monotonic_time(:millisecond)

  @impl true
  @doc false
  def handle_call(
        {:get_token, cap, dur},
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
