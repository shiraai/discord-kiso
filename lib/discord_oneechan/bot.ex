defmodule DiscordOneechan.Bot do
  use Din.Module
  alias Din.Resources.{Channel, Guild, User}
  import DiscordOneechan.Util

  # Enforcers -----------------------------------------------------------------

  def admin(data) do
    # Checks the below user IDs for confirmed admins on a global scale.
    user_ids = ["66654117510000640", "107977662680571904", "96672649966518272", "148298236824649728"]
    Enum.member?(user_ids, data.author.id)
  end

  def watched(data) do
    # Checks to see if the channel the message recieved is coming from
    # a watched cahnnel.
    chans = query_data(:chans, 0)

    case chans do
      nil -> false
      chans -> Enum.member?(chans, data.channel_id)
    end
  end

  # Event handlers ------------------------------------------------------------

  # New message handlers
  handle :message_create do
    # Admin only commands
    enforce :admin do
      match "!ping", :ping # Simple ping test
      match "!watch", :watch # Adds current channel to the watch list
      match "!stop", :stop # Stops watching current channel
      match "!role", :add_role_command # Creates custom commands to add roles
      match "!update", :update # Command to update an edited or removed message
    end

    # Any user commands
    match "!done", :remove_custom_role # Removes custom roles
    custom_role(data) # Used to add custom roles created by admins using !role

    # A "role list" is created in a channel by creating messages with roles
    # in the message. The bot then creates a reaction to that message. When
    # a user reacts to the message, they are added to the role.
    #
    # Below is the handler for initializing the role messages and creating the
    # intial reaction for users to react to.
    #
    # An ❌ is created when there is an issue during initialization.
    enforce :watched do
      role = data.mention_roles

      case role do
        # No role is specified
        [] -> Channel.create_reaction(data.channel_id, data.id, "❌")
        # A single role is specified
        [role] ->
          store_data(:roles, data.id, role)
          Channel.create_reaction(data.channel_id, data.id, "✅")
        # More than one role is specified
        _roles -> Channel.create_reaction(data.channel_id, data.id, "❌")
      end
    end
  end

  # Deleted message handler
  #
  # Removes the role data if the post is deleted from a watched channel.
  handle :message_delete do
    enforce :watched do
      role = query_data(:roles, data.id)

      case role do
        nil -> nil
        _role -> delete_data(:roles, data.id)
      end
    end
  end

  # Reaction added handler
  #
  # Adds the user to the role if they react to the specified message
  # in a watched channel.
  handle :message_reaction_add do
    enforce :watched do
      guild_id = Channel.get(data.channel_id).guild_id
      role = query_data(:roles, data.message_id)

      Guild.add_member_role(guild_id, data.user_id, role)
    end
  end

  # Reaction removed handler
  #
  # Removes the role from a user if they remove their reaction to a
  # specified message.
  handle :message_reaction_remove do
    enforce :watched do
      guild_id = Channel.get(data.channel_id).guild_id
      role = query_data(:roles, data.message_id)

      Guild.remove_member_role(guild_id, data.user_id, role)
    end
  end

  # Passthrough for all other messages that don't match the above.
  handle_fallback()

  # Command functions ---------------------------------------------------------

  # Administrative commands

  # Simple ping command.
  def ping(data) do
    IO.inspect data
    reply "Pong!"
  end

  # Sets specified channel to watch for new role posts.
  def watch(data) do
    chans = query_data(:chans, 0)

    case chans do
      nil -> store_data(:chans, 0, [data.channel_id])
      chans -> store_data(:chans, 0, chans ++ [data.channel_id] |> Enum.uniq)
    end

    Channel.create_reaction(data.channel_id, data.id, "✅")
  end

  # Stops watching specified channel.
  def stop(data) do
    chans = query_data(:chans, 0)

    case chans do
      nil -> store_data(:chans, 0, [])
      chans -> store_data(:chans, 0, chans -- [data.channel_id] |> Enum.uniq)
    end

    Channel.create_reaction(data.channel_id, data.id, "✅")
  end

  # Creates role commands.
  #
  # Example, !role team1 @team1 will create a command for users to use.
  # Typing !team1 will add the role @team1 to themselves.
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

  # Deletes created role commands.
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

  # This is the checker for users when they use role commands.
  def custom_role(data) do
    # Checks to see if the user typed a role command, and returns the role ID.
    role = query_data(:commands, data.content |> String.split |> List.first)

    case role do
      nil -> nil
      role ->
        roles = query_data(:commands, :roles)
        guild_id = Channel.get(data.channel_id).guild_id
        member = Guild.get_member(guild_id, data.author.id)

        cond do
          # Checks to see the member is already part of that role.
          Enum.member?(member.roles, role) ->
            Channel.create_reaction(data.channel_id, data.id, "❌")
          # Removes any other custom roles that have already been added.
          true ->
            for member_role <- member.roles do
              if Enum.member?(roles, member_role) do
                Guild.remove_member_role(guild_id, data.author.id, member_role)
              end
            end

            # Adds the new role to the user.
            Guild.add_member_role(guild_id, data.author.id, role)
            Channel.create_reaction(data.channel_id, data.id, "✅")
        end
    end
  end

  # Removes custom role from a user.
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

  # Command to re-add messages that got dropped for whatever reason.
  def update(data) do
    [_ | [message_id | _]] = data.content |> String.split
    message_data = Channel.get_message(data.channel_id, message_id)

    # Re-processes the specified message contents.
    case message_data.mention_roles do
      # No role is specified
      [] -> Channel.create_reaction(data.channel_id, data.id, "❌")
      # A single role is specified
      [role] ->
        # Re-add message to the database
        store_data(:roles, message_data.id, role)

        # Re-adds roles to users.
        reactions = Channel.get_reactions(data.channel_id, message_data.id, "✅")

        for user <- reactions do
          guild_id = Channel.get(data.channel_id).guild_id
          role = query_data(:roles, message_data.id)

          unless user.id == User.get_current_user().id do
            Guild.add_member_role(guild_id, user.id, role)
          end
        end

        Channel.create_reaction(data.channel_id, data.id, "✅")
      _ ->
        cond do
          # More than one role is specified
          length(message_data.mention_roles) > 1 ->
            Channel.create_reaction(data.channel_id, data.id, "❌")
          # Something else happened and broke
          true ->
            Channel.create_reaction(data.channel_id, data.id, "❔")
            Logger.error "Error in !update command."

            Logger.warn "Original message:"
            IO.inspect data

            Logger.warn "Message to update:"
            IO.inspect message_data
        end
    end
  end
end
