defmodule EventStore.Migrator.Tasks.WriteTempEvent do
  def execute(conn, event, event_id, stream_version, serializer) do
    Postgrex.query!(conn, insert_statement(), [
      event_id,
      event.event_id,
      event.stream_id,
      stream_version,
      event.correlation_id,
      event.event_type,
      serializer.serialize(event.data),
      serializer.serialize(event.metadata),
      event.created_at,
    ])
  end

  defp insert_statement do
"""
INSERT INTO temp_events (event_id, original_event_id, stream_id, stream_version, correlation_id, event_type, data, metadata, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
"""
  end
end
