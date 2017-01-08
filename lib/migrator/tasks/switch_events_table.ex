defmodule EventStore.Migrator.Tasks.SwitchEventsTable do
  def execute(conn) do
    rename_table(conn, "events", "original_events")
    rename_table(conn, "temp_events", "events")
    drop_column(conn, "events", "original_event_id")
  end

  defp rename_table(conn, from, to) do
    Postgrex.query!(conn, "ALTER TABLE #{from} RENAME to #{to};", [])
  end

  defp drop_column(conn, table, column) do
    Postgrex.query!(conn, "ALTER TABLE #{table} DROP COLUMN #{column};", [])
  end
end
