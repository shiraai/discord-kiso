defmodule DiscordKiso do
  use Application
  use Supervisor
  require Logger

  unless File.exists?("_db"), do: File.mkdir("_db")

  def start(_type, _args) do
    import Supervisor.Spec
    Logger.info "Starting supervisor..."

    children = for i <- 1..System.schedulers_online, do: worker(DiscordKiso.Bot, [], id: i)
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
