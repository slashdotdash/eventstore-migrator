defmodule EventStore.Migrator.StorageCase do
  use ExUnit.CaseTemplate

  setup do
    source_config = Application.get_env(:eventstore, EventStore.Storage)
    target_config = Application.get_env(:eventstore_migrator, EventStore.Migrator)

    Application.stop(:eventstore)

    reset_storage(source_config)
    create_target_storage(target_config)
    drop_tables(target_config)

    Application.ensure_all_started(:eventstore)

    :ok
  end

  defp reset_storage(storage_config) do
    {:ok, conn} = Postgrex.start_link(storage_config)

    EventStore.Storage.Initializer.reset!(conn)
  end

  defp create_target_storage(storage_config) do
    System.cmd("createdb", [storage_config[:database]], stderr_to_stdout: true)
  end

  defp drop_tables(storage_config) do
    {:ok, conn} = Postgrex.start_link(storage_config)

    EventStore.Storage.Initializer.reset!(conn)

    drop_table(conn, "snapshots")
    drop_table(conn, "subscriptions")
    drop_table(conn, "streams, events")
    drop_table(conn, "events")
  end

  defp drop_table(conn, table) do
    Postgrex.query!(conn, "DROP TABLE IF EXISTS #{table}", [])
  end
end
