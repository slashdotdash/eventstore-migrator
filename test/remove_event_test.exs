defmodule EventStore.RemoveEventTest do
  use EventStore.Migrator.StorageCase

  defmodule WantedEvent, do: defstruct [uuid: nil]
  defmodule UnwantedEvent, do: defstruct [uuid: nil]

  describe "remove an event" do
    setup [:append_events, :migrate]

    @tag :wip
    test "should remove only unwanted events" do
      {:ok, events} = EventStore.read_all_streams_forward()

      IO.inspect events
      assert length(events) == 2
      assert pluck(events, :event_id) == [1, 2]
      assert pluck(events, :stream_version) == [1, 2]
    end
  end

  defp migrate(context) do
    EventStore.Migrator.migrate(fn event_data ->
      case event_data.event_type do
        "Elixir.EventStore.RemoveEventTest.UnwantedEvent" -> :skip
        _ -> :copy
      end
    end)
    context
  end

  defp append_events(_context) do
    stream_uuid = UUID.uuid4()
    correlation_id = UUID.uuid4()

    events = [
      to_event_data(correlation_id, %WantedEvent{uuid: 1}),
      to_event_data(correlation_id, %UnwantedEvent{uuid: 2}),
      to_event_data(correlation_id, %WantedEvent{uuid: 3}),
    ]

    EventStore.append_to_stream(stream_uuid, 0, events)

    [stream_uuid: stream_uuid]
  end

  defp to_event_data(correlation_id, event) do
    %EventStore.EventData{
      correlation_id: correlation_id,
      event_type: Atom.to_string(event.__struct__),
      data: event,
      metadata: %{},
    }
  end

  def pluck(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end
end
