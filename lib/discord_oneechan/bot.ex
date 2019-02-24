defmodule DiscordOneechan.Bot do
  use Din.Module
  alias Din.Resources.{Channel, Guild}
  import DiscordOneechan.Util

  # Enforcers
  def admin(data) do
    user_ids = ["66654117510000640", "107977662680571904", "96672649966518272", "148298236824649728"]
    Enum.member?(user_ids, data.author.id)
  end

  def watched(data) do
    chans = query_data(:chans, 0)

    case chans do
      nil -> false
      chans -> Enum.member?(chans, data.channel_id)
    end
  end

  # Event handlers
  handle :message_create do
    enforce :admin do
      match "!ping", :ping
      match "!watch", :watch
      match "!stop", :stop
      match "!role", :add_role_command
    end

    match "!done", :remove_custom_role
    custom_role(data)

    enforce :watched do
      role = data.mention_roles

      case role do
        [] -> Channel.create_reaction(data.channel_id, data.id, "❌")
        [role] ->
          store_data(:roles, data.id, role)
          Channel.create_reaction(data.channel_id, data.id, "✅")
        _roles -> Channel.create_reaction(data.channel_id, data.id, "❌")
      end
    end
  end

  handle :message_delete do
    enforce :watched do
      role = query_data(:roles, data.id)

      case role do
        nil -> nil
        _role -> delete_data(:roles, data.id)
      end
    end
  end

  handle :message_reaction_add do
    enforce :watched do
      guild_id = Channel.get(data.channel_id).guild_id
      role = query_data(:roles, data.message_id)

      Guild.add_member_role(guild_id, data.user_id, role)
    end
  end

  handle :message_reaction_remove do
    enforce :watched do
      guild_id = Channel.get(data.channel_id).guild_id
      role = query_data(:roles, data.message_id)

      Guild.remove_member_role(guild_id, data.user_id, role)
    end
  end

  handle_fallback()

  # Administrative commands
  def ping(data) do
    IO.inspect data
    reply "Pong!"
  end

  def watch(data) do
    chans = query_data(:chans, 0)

    case chans do
      nil -> store_data(:chans, 0, [data.channel_id])
      chans -> store_data(:chans, 0, chans ++ [data.channel_id] |> Enum.uniq)
    end

    Channel.create_reaction(data.channel_id, data.id, "✅")
  end

  def stop(data) do
    chans = query_data(:chans, 0)

    case chans do
      nil -> store_data(:chans, 0, [])
      chans -> store_data(:chans, 0, chans -- [data.channel_id] |> Enum.uniq)
    end

    Channel.create_reaction(data.channel_id, data.id, "✅")
  end

  def add_role_command(data) do
    [_ | [command | _]] = data.content |> String.split
    role = data.mention_roles |> List.first

    roles = query_data(:commands, :roles)
    roles = case roles do
      nil -> []
      roles -> roles
    end

    store_data(:commands, "!#{command}", role)
    store_data(:commands, :roles, roles ++ [role])

    Channel.create_reaction(data.channel_id, data.id, "✅")
  end

  def del_role_command(data) do
    [_ | [command | _]] = data.content |> String.split
    role = query_data(:commands, "!#{command}")

    case role do
      nil -> reply "Command does not exist."
      role ->
        roles = query_data(:commands, :roles)

        store_data(:commands, :roles, roles -- [role])
        delete_data(:commands, "!#{command}")
        Channel.create_reaction(data.channel_id, data.id, "✅")
    end
  end

  def custom_role(data) do
    role = query_data(:commands, data.content |> String.split |> List.first)

    case role do
      nil -> nil
      role ->
        roles = query_data(:commands, :roles)
        guild_id = Channel.get(data.channel_id).guild_id
        member = Guild.get_member(guild_id, data.author.id)

        cond do
          Enum.member?(member.roles, role) ->
            Channel.create_reaction(data.channel_id, data.id, "❌")
          true ->
            for member_role <- member.roles do
              if Enum.member?(roles, member_role) do
                Guild.remove_member_role(guild_id, data.author.id, member_role)
              end
            end

            Guild.add_member_role(guild_id, data.author.id, role)
            Channel.create_reaction(data.channel_id, data.id, "✅")
        end
    end
  end

  def remove_custom_role(data) do
    roles = query_data(:commands, :roles)
    guild_id = Channel.get(data.channel_id).guild_id
    member = Guild.get_member(guild_id, data.author.id)

    for member_role <- member.roles do
      if Enum.member?(roles, member_role) do
        Guild.remove_member_role(guild_id, data.author.id, member_role)
      end
    end

    Channel.create_reaction(data.channel_id, data.id, "✅")
  end
end
