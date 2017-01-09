defmodule EventStore.Migrator.Tasks.WriteTempEvent do
  defmodule State do
    defstruct [
      conn: nil,
      serializer: nil,
      next_event_id: 1,
      stream_versions: %{},
    ]
  end

  alias EventStore.Migrator.Tasks.WriteTempEvent.State

  def execute(events, conn, serializer) do
    Stream.transform(
      events,
      %State{conn: conn, serializer: serializer},
      fn (event, state) -> write(event, state) end
    )
  end

  defp write(event, %State{conn: conn, serializer: serializer, next_event_id: next_event_id, stream_versions: stream_versions} = state) do
    stream_version = Map.get(stream_versions, event.stream_id, 0) + 1

    insert(state, event, next_event_id, stream_version)

    state = %State{state |
      next_event_id: next_event_id + 1,
      stream_versions: Map.put(stream_versions, event.stream_id, stream_version)
    }

    {[event], state}
  end

  defp insert(%State{conn: conn, serializer: serializer}, event, event_id, stream_version) do
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
