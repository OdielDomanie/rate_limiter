defmodule RateLimiter.Application do
  use Application

  @impl Application
  def start(_start_type, _start_args) do
    DynamicSupervisor.start_link(name: RateLimiter.Supervisor)
  end
end
