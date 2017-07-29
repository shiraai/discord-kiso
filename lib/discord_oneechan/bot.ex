defmodule DiscordOneechan.Bot do
  use DiscordOneechan.Module
  import DiscordOneechan.Util

  # Event handlers
  handle :MESSAGE_CREATE do
    match "!help", do: reply "https://github.com/shiraai/discord-oneechan"
    match "!ping", :ping
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  def ping(msg) do
    IO.inspect msg
    reply "Pong!"
  end
end
