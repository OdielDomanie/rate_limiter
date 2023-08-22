defmodule RateLimiterTest do
  use ExUnit.Case
  doctest RateLimiter

  test "rate_limit_manual_start" do
    {:ok, _rate_limiter} =
      RateLimiter.start_link(
        name: :test_rl,
        cap: 20,
        duration: 500
      )

    start = System.monotonic_time(:millisecond)

    fun = fn ->
      RateLimiter.rate_limit(:test_rl)
      nil
    end

    1..100
    |> Task.async_stream(fn _ -> fun.() end, max_concurrency: 10_000)
    |> Stream.run()

    fin = System.monotonic_time(:millisecond)

    assert_in_delta fin - start, 2000, 300
  end
end
