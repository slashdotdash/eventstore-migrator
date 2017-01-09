defmodule EventStore.Migrator.AggregateEventsTest do
  use EventStore.Migrator.StorageCase

  alias EventStore.Migrator.EventFactory

  defmodule SingleEvent, do: defstruct [uuid: nil, group: nil]
  defmodule AggregatedEvent, do: defstruct [uuids: [], group: nil]

  describe "combine events" do
    setup [:append_events, :migrate]

    @tag :wip
    test "should remove individual events and replace with aggregated event" do
      {:ok, events} = EventStore.Migrator.Reader.read_migrated_events()

      assert length(events) == 4
      assert pluck(events, :event_id) == [1, 2, 3, 4]
      assert pluck(events, :stream_version) == [1, 1, 1, 1]
      assert pluck(events, :event_type) == [
        "#{__MODULE__}.AggregatedEvent",
        "#{__MODULE__}.SingleEvent",
        "#{__MODULE__}.SingleEvent",
        "#{__MODULE__}.AggregatedEvent",
      ]
      assert Enum.at(events, 0).data == "{\"uuids\":[1,2,3],\"group\":\"A\"}"
    end

    test "should copy stream", context do
      {:ok, stream_id, stream_version} = EventStore.Migrator.Reader.stream_info(context[:stream1_uuid])

      assert stream_id == 1
      assert stream_version == 1
    end
  end

  defp migrate(context) do
    EventStore.Migrator.migrate(fn stream ->
      stream
      |> Stream.chunk_by(fn event -> {event.stream_id, event.event_type} end)
      |> Stream.map(fn events -> aggregate(events) end)
      |> Stream.flat_map(fn events -> events end)
    end)

    context
  end

  # aggregate multiple single events for the same group into one aggregated event
  defp aggregate([%{data: %SingleEvent{}}] = events), do: events
  defp aggregate([%{data: %SingleEvent{group: group}} = source | _] = events) do
    [
      %EventStore.RecordedEvent{source |
        data: %AggregatedEvent{
          uuids: Enum.map(events, fn event -> event.data.uuid end),
          group: group,
        },
        event_type: "#{__MODULE__}.AggregatedEvent",
      },
    ]
  end
  defp aggregate(events), do: events

  defp append_events(_context) do
    stream1_uuid = UUID.uuid4()
    stream2_uuid = UUID.uuid4()
    stream3_uuid = UUID.uuid4()
    stream4_uuid = UUID.uuid4()

    EventStore.append_to_stream(stream1_uuid, 0, EventFactory.to_event_data([
      %SingleEvent{uuid: 1, group: "A"},
      %SingleEvent{uuid: 2, group: "A"},
      %SingleEvent{uuid: 3, group: "A"}
    ]))

    EventStore.append_to_stream(stream2_uuid, 0, EventFactory.to_event_data([
      %SingleEvent{uuid: 4, group: "B"},
    ]))

    EventStore.append_to_stream(stream3_uuid, 0, EventFactory.to_event_data([
      %SingleEvent{uuid: 5, group: "C"},
    ]))

    EventStore.append_to_stream(stream4_uuid, 0, EventFactory.to_event_data([
      %SingleEvent{uuid: 6, group: "D"},
      %SingleEvent{uuid: 7, group: "D"},
    ]))

    [
      stream1_uuid: stream1_uuid,
      stream2_uuid: stream2_uuid,
      stream3_uuid: stream3_uuid,
      stream4_uuid: stream4_uuid,
    ]
  end

  def pluck(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end
end
