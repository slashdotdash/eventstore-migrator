defmodule EventStore.AggregateEventsTest do
  use EventStore.Migrator.StorageCase

  alias EventStore.Migrator.EventFactory

  defmodule SingleEvent, do: defstruct [uuid: nil, group: nil]
  defmodule AggregatedEvent, do: defstruct [uuids: [], group: nil]

  describe "combine events" do
    setup [:append_events, :migrate]

    test "should remove individual events and replace with aggregated event" do
      {:ok, events} = EventStore.read_all_streams_forward()

      assert length(events) == 4
      assert pluck(events, :event_id) == [1, 2, 3, 4]
      assert pluck(events, :stream_version) == [1, 1, 1, 1]
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

  defp aggregate([%{data: %EventStore.AggregateEventsTest.SingleEvent{group: group}} = source | _] = events) do
    [
      %EventStore.RecordedEvent{source |
        data: %AggregatedEvent{
          uuids: Enum.map(events, fn event -> event.data.uuid end),
          group: group,
        },
      },
    ]
  end
  defp aggregate(events), do: events

  defp append_events(_context) do
    EventStore.append_to_stream(UUID.uuid4(), 0, EventFactory.to_event_data([
      %SingleEvent{uuid: 1, group: "A"},
      %SingleEvent{uuid: 2, group: "A"},
      %SingleEvent{uuid: 3, group: "A"}
    ]))

    EventStore.append_to_stream(UUID.uuid4(), 0, EventFactory.to_event_data([
      %SingleEvent{uuid: 4, group: "B"},
    ]))

    EventStore.append_to_stream(UUID.uuid4(), 0, EventFactory.to_event_data([
      %SingleEvent{uuid: 5, group: "C"},
    ]))

    EventStore.append_to_stream(UUID.uuid4(), 0, EventFactory.to_event_data([
      %SingleEvent{uuid: 6, group: "D"},
      %SingleEvent{uuid: 7, group: "D"},
    ]))

    []
  end

  def pluck(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end
end
