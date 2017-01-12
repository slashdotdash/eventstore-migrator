defmodule EventStore.Migrator.Tasks.WriteEvents do
  defmodule State do
    defstruct [
      conn: nil,
      serializer: nil,
      next_event_id: 1,
      stream_versions: %{},
    ]
  end

  alias EventStore.Migrator.Tasks.WriteEvents.State

  def execute(events, %{conn: conn, serializer: serializer} = config, write_batch_size \\ 1_000) do
    events
    |> Stream.transform(%State{conn: conn, serializer: serializer}, &map_to_recorded_event/2)
    |> Stream.chunk(write_batch_size, write_batch_size, [])
    |> Stream.each(&append_event_batch(&1, config))
  end

  defp map_to_recorded_event(event, %State{next_event_id: next_event_id, serializer: serializer, stream_versions: stream_versions} = state) do
    stream_version = Map.get(stream_versions, event.stream_id, 0) + 1

    recorded_event = %EventStore.RecordedEvent{
      event_id: next_event_id,
      stream_id: event.stream_id,
      stream_version: stream_version,
      correlation_id: event.correlation_id,
      event_type: event.event_type,
      data: serializer.serialize(event.data),
      metadata: serializer.serialize(event.metadata),
      created_at: event.created_at,
    }

    state = %State{state |
      next_event_id: next_event_id + 1,
      stream_versions: Map.put(stream_versions, event.stream_id, stream_version)
    }

    {[recorded_event], state}
  end

  defp append_event_batch(events, %{conn: conn}) do
    expected_count = length(events)

    {:ok, ^expected_count} = execute_using_multirow_value_insert(conn, events)
  end

  defp execute_using_multirow_value_insert(conn, events) do
    statement = build_insert_statement(events)
    parameters = build_insert_parameters(events)

    conn
    |> Postgrex.query(statement, parameters)
    |> handle_response()
  end

  defp build_insert_statement(events) do
    EventStore.Sql.Statements.create_events(length(events))
  end

  defp build_insert_parameters(events) do
    events
    |> Enum.flat_map(fn event ->
      [
        event.event_id,
        event.stream_id,
        event.stream_version,
        event.correlation_id,
        event.event_type,
        event.data,
        event.metadata,
        event.created_at,
      ]
    end)
  end

  defp handle_response({:ok, %Postgrex.Result{num_rows: rows}}), do: {:ok, rows}
  defp handle_response({:error, reason}), do: {:error, reason}
end
