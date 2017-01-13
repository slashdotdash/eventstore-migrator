defmodule EventStore.Migrator.Tasks.ResetTableSequence do
  def execute(conn, table, primary_key) do
    Postgrex.query!(conn, reset_stream_sequence(table, primary_key), [])
  end

  defp reset_stream_sequence(table, primary_key) do
"""
SELECT setval('#{table}_#{primary_key}_seq', COALESCE((SELECT MAX(#{primary_key}) + 1 FROM #{table}), 1), false);
"""
  end
end
