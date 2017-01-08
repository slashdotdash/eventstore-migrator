defmodule EventStore.Migrator.Tasks.CreateTempEventsTable do
  def execute(conn) do
    Postgrex.query!(conn, create_temp_events_table(), [])
  end

  defp create_temp_events_table do
"""
CREATE TABLE temp_events
(
  event_id bigint PRIMARY KEY NOT NULL,
  original_event_id bigint NOT NULL,
  stream_id bigint NOT NULL REFERENCES streams (stream_id),
  stream_version bigint NOT NULL,
  event_type text NOT NULL,
  correlation_id text,
  data bytea NOT NULL,
  metadata bytea NULL,
  created_at timestamp without time zone NOT NULL
);
"""
  end
end
