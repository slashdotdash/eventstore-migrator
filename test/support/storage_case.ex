defmodule EventStore.Migrator.StorageCase do
  use ExUnit.CaseTemplate

  alias EventStore.Storage

  setup do
    Application.stop(:eventstore)
    reset_storage()
    Application.ensure_all_started(:eventstore)

    :ok
  end

  defp reset_storage do
    storage_config = Application.get_env(:eventstore, Storage)

    {:ok, conn} = Postgrex.start_link(storage_config)

    Postgrex.query!(conn, "ALTER TABLE events DROP COLUMN IF EXISTS original_event_id;", [])
    Postgrex.query!(conn, "DROP TABLE IF EXISTS temp_events;", [])
    Postgrex.query!(conn, "DROP TABLE IF EXISTS original_events;", [])

    Storage.Initializer.reset!(conn)
  end
end
