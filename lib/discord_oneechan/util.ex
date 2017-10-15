defmodule DiscordOneechan.Util do
  require Logger

  def store_data(table, key, value) do
    file = '_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])

    :dets.insert(table, {key, value})
    :dets.close(table)
    :ok
  end

  def query_data(table, key) do
    file = '_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    result = :dets.lookup(table, key)

    response =
      case result do
        [{_, value}] -> value
        [] -> nil
      end

    :dets.close(table)
    response
  end

  def query_all_data(table) do
    file = '_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    result = :dets.match_object(table, {:"$1", :"$2"})

    response =
      case result do
        [] -> nil
        values -> values
      end

    :dets.close(table)
    response
  end

  def delete_data(table, key) do
    file = '_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    response = :dets.delete(table, key)

    :dets.close(table)
    response
  end

  def update_db do
    # Updates roles
    for {message_id, role_id} <- query_all_data(:roles) do
      delete_data :roles, message_id
      store_data :roles, Integer.to_string(message_id), Integer.to_string(role_id)
    end

    # Updates chans
    delete_data :chans, 0
    store_data :chans, 0, ["340760692934180864"]

    # Updates commands
    delete_data :commands, :roles
    for {command, role_id} <- query_all_data(:roles) do
      delete_data :commands, command
      store_data :commands, command, Integer.to_string(role_id)
    end
    store_data :chans, :roles, ["305341291158437888", "305341344031703042", "305341347106127872","305341400114003989", "315608541425565699", "315608547218030593", "315608550418284555", "315613276689924098", "315613315017736194", "305352524133564418", "305352524133564418"]
  end
end
