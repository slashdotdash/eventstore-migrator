defmodule EventStore.RemoveEventTest do
  use EventStore.Migrator.StorageCase

  alias EventStore.Migrator.EventFactory

  defmodule WantedEvent, do: defstruct [uuid: nil]
  defmodule UnwantedEvent, do: defstruct [uuid: nil]

  describe "remove an event" do
    setup [:append_events, :migrate]

    test "should remove only unwanted events" do
      {:ok, events} = EventStore.Migrator.Reader.read_migrated_events()

      assert length(events) == 2
      assert pluck(events, :event_id) == [1, 2]
      assert pluck(events, :stream_version) == [1, 2]
    end

    test "should copy stream", context do
      {:ok, stream_id, stream_version} = EventStore.Migrator.Reader.stream_info(context[:stream_uuid])

      assert stream_id == 1
      assert stream_version == 2
    end
  end

  describe "remove all events from a stream" do
    setup [:append_unwanted_events_to_single_stream, :migrate]

    test "should remove all unwanted events" do
      {:ok, events} = EventStore.Migrator.Reader.read_migrated_events()

      assert length(events) == 0
    end

    test "should remove stream", context do
      {:ok, stream_id, stream_version} = EventStore.Migrator.Reader.stream_info(context[:stream_uuid])

      assert stream_id == nil
      assert stream_version == 0
    end
  end

  defp migrate(context) do
    EventStore.Migrator.migrate(fn stream ->
      Stream.reject(
        stream,
        fn (event_data) -> event_data.event_type == "Elixir.EventStore.RemoveEventTest.UnwantedEvent" end
      )
    end)

    context
  end

  defp append_events(_context) do
    stream_uuid = UUID.uuid4()

    events = EventFactory.to_event_data([
      %WantedEvent{uuid: 1},
      %UnwantedEvent{uuid: 2},
      %WantedEvent{uuid: 3}
    ])

    EventStore.append_to_stream(stream_uuid, 0, events)

    [stream_uuid: stream_uuid]
  end

  defp append_unwanted_events_to_single_stream(_context) do
    stream_uuid = UUID.uuid4()

    events = EventFactory.to_event_data([
      %UnwantedEvent{uuid: 1},
      %UnwantedEvent{uuid: 2},
      %UnwantedEvent{uuid: 3}
    ])

    EventStore.append_to_stream(stream_uuid, 0, events)

    [stream_uuid: stream_uuid]
  end

  def pluck(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end
end
