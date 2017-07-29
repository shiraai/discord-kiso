defmodule DiscordOneechan.Bot do
  use DiscordOneechan.Module
  import DiscordOneechan.Util

  # Enforcers
  def admin(msg) do
    user_ids = [66654117510000640, 107977662680571904]
    Enum.member?(user_ids, msg.author.id)
  end

  def watched(msg) do
    chans = query_data(:chans, 0)

    case chans do
      nil -> false
      chans -> Enum.member?(chans, msg.channel_id)
    end
  end

  # Event handlers
  handle :MESSAGE_CREATE do
    match "!help", do: reply "https://github.com/shiraai/discord-oneechan"

    enforce :admin do
      match "!ping", :ping
      match "!watch", :watch
    end

    enforce :watched do
      role = msg.mention_roles

      case role do
        [] -> Nostrum.Api.create_reaction(msg.channel_id, msg.id, "❌")
        [role] ->
          store_data(:roles, msg.id, role)
          Nostrum.Api.create_reaction(msg.channel_id, msg.id, "✅")
        roles -> Nostrum.Api.create_reaction(msg.channel_id, msg.id, "❌")
      end
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

  def watch(msg) do
    chans = query_data(:oneechan, 0)

    case chans do
      nil -> store_data(:chans, 0, [msg.channel_id])
      chans -> store_data(:chans, 0, chans ++ msg.channel_id |> Enum.uniq)
    end
  end
end
