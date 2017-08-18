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
    enforce :admin do
      match "!ping", :ping
      match "!watch", :watch
      match "!stop", :stop
      match "!role", :add_role_command
    end

    match "!done", :remove_custom_role
    match_all :custom_role

    enforce :watched do
      role = msg.mention_roles

      case role do
        [] -> Nostrum.Api.create_reaction(msg.channel_id, msg.id, "❌")
        [role] ->
          store_data(:roles, msg.id, role)
          Nostrum.Api.create_reaction(msg.channel_id, msg.id, "✅")
        _roles -> Nostrum.Api.create_reaction(msg.channel_id, msg.id, "❌")
      end
    end
  end

  handle :MESSAGE_DELETE do
    enforce :watched do
      role = query_data(:roles, msg.id)

      case role do
        nil -> nil
        _role -> delete_data(:roles, msg.id)
      end
    end
  end

  handle :MESSAGE_REACTION_ADD do
    enforce :watched do
      guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
      role = query_data(:roles, msg.message_id)

      Nostrum.Api.add_guild_member_role(guild_id, msg.user_id, role)
    end
  end

  handle :MESSAGE_REACTION_REMOVE do
    enforce :watched do
      guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
      role = query_data(:roles, msg.message_id)

      Nostrum.Api.remove_guild_member_role(guild_id, msg.user_id, role)
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
    chans = query_data(:chans, 0)

    case chans do
      nil -> store_data(:chans, 0, [msg.channel_id])
      chans -> store_data(:chans, 0, chans ++ [msg.channel_id] |> Enum.uniq)
    end

    Nostrum.Api.create_reaction(msg.channel_id, msg.id, "✅")
  end

  def stop(msg) do
    chans = query_data(:chans, 0)

    case chans do
      nil -> store_data(:chans, 0, [])
      chans -> store_data(:chans, 0, chans -- [msg.channel_id] |> Enum.uniq)
    end

    Nostrum.Api.create_reaction(msg.channel_id, msg.id, "✅")
  end

  def add_role_command(msg) do
    [_ | [command | _]] = msg.content |> String.split
    role = msg.mention_roles |> List.first

    exists = query_data(:commands, "!#{command}")
    roles = query_data(:commands, :roles)
    roles = case roles do
      nil -> []
      roles -> roles
    end

    store_data(:commands, "!#{command}", role)
    store_data(:commands, :roles, roles ++ [role])

    case exists do
      nil -> reply "Alright! Type !#{command} to use."
      _   -> reply "Done, command !#{command} updated."
    end
  end

  def del_role_command(msg) do
    [_ | [command | _]] = msg.content |> String.split
    role = query_data(:commands, "!#{command}")

    case role do
      nil -> reply "Command does not exist."
      role ->
        roles = query_data(:commands, :roles)

        store_data(:commands, :roles, roles -- [role])
        delete_data(:commands, "!#{command}")
        reply "Command !#{command} removed."
    end
  end

  def custom_role(msg) do
    role = query_data(:commands, msg.content |> String.split |> List.first)

    case role do
      nil -> nil
      role ->
        roles = query_data(:commands, :roles)
        guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
        {:ok, member} = Nostrum.Api.get_member(guild_id, msg.author.id)

        cond do
          Enum.member?(member["roles"], role) -> reply "You already have that role."
          true ->
            for member_role <- member["roles"] do
              if Enum.member?(roles, member_role) do
                Nostrum.Api.remove_guild_member_role(guild_id, msg.author.id, member_role)
              end
            end

            Nostrum.Api.add_guild_member_role(guild_id, msg.author.id, role)
        end
    end
  end

  def remove_custom_role(msg) do
    roles = query_data(:commands, :roles)
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    {:ok, member} = Nostrum.Api.get_member(guild_id, msg.author.id)

    for member_role <- member["roles"] do
      if Enum.member?(roles, member_role) do
        Nostrum.Api.remove_guild_member_role(guild_id, msg.author.id, member_role)
      end
    end
  end
end
