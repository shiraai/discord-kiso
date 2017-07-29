defmodule DiscordOneechan.Bot do
  use DiscordOneechan.Module
  import DiscordOneechan.Util

  # Enforcers
  def admin(msg) do
    user_id = 66654117510000640
    msg.author.id == user_id
  end

  # Event handlers
  handle :MESSAGE_CREATE do
    match "!help", do: reply "https://github.com/shiraai/discord-oneechan"

    enforce :admin do
      match "!ping", :ping
    end
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  # Administrative commands
  def ping(msg) do
    IO.inspect msg
    reply "Pong!"
  end
end
