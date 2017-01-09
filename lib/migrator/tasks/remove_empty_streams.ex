defmodule EventStore.Migrator.Tasks.RemoveEmptyStreams do
  def execute(conn) do
    Postgrex.query!(conn, remove_empty_streams(), [])
  end

  defp remove_empty_streams do
"""
DELETE FROM streams s
WHERE NOT EXISTS
  (SELECT stream_id FROM events e
   WHERE e.stream_id = s.stream_id
   LIMIT 1);
"""
  end
end
