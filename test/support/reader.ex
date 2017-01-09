defmodule EventStore.Migrator.Reader do
  def read_migrated_events do
    EventStore.Storage.Reader.read_all_forward(conn(), 0, 1_000)
  end

  def stream_info(stream_uuid) do
    EventStore.Storage.Stream.stream_info(conn(), stream_uuid)
  end

  defp conn do
    storage_config = Application.get_env(:eventstore_migrator, EventStore.Migrator)

    {:ok, conn} = Postgrex.start_link(storage_config)

    conn
  end
end
