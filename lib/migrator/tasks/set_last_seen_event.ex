defmodule EventStore.Migrator.Tasks.SetLastSeenEvent do
  def execute(conn) do
    Postgrex.query!(conn, set_all_stream_subscription_last_seen_event_id(), [])
    Postgrex.query!(conn, set_single_stream_subscription_last_seen_event_id(), [])
    Postgrex.query!(conn, set_snapshots_last_seen_event_id(), [])
  end

  defp set_all_stream_subscription_last_seen_event_id do
"""
UPDATE subscriptions s
SET last_seen_event_id =
  (SELECT COALESCE(MAX(e.event_id), 0)
   FROM events e)
WHERE s.stream_uuid = '$all';
"""
  end

  defp set_single_stream_subscription_last_seen_event_id do
"""
UPDATE subscriptions
SET last_seen_stream_version =
  (SELECT COALESCE(MAX(events.event_id), 0)
   FROM events
   WHERE events.stream_id =
     (SELECT streams.stream_id
      FROM streams
      WHERE streams.stream_uuid = subscriptions.stream_uuid))
WHERE subscriptions.stream_uuid <> '$all';
"""
  end

  defp set_snapshots_last_seen_event_id do
"""
UPDATE snapshots s
SET source_version =
  (SELECT COALESCE(MAX(e.event_id), 0)
   FROM events e);
"""
  end
end
