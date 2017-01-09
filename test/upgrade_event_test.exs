defmodule EventStore.UpgradeEventTest do
  use EventStore.Migrator.StorageCase

  alias EventStore.Migrator.EventFactory

  defmodule OriginalEvent, do: defstruct [uuid: nil]
  defmodule UpgradedEvent, do: defstruct [uuid: nil, additional: nil]
  defmodule AnotherEvent, do: defstruct [uuid: nil]

  describe "upgrade an event" do
    setup [:append_events, :migrate]

    test "should upgrade only matching events" do
      {:ok, events} = EventStore.read_all_streams_forward()

      assert length(events) == 3
      assert pluck(events, :event_id) == [1, 2, 3]
      assert pluck(events, :stream_version) == [1, 2, 3]
      assert pluck(events, :event_type) == [
        "Elixir.EventStore.UpgradeEventTest.AnotherEvent",
        "Elixir.EventStore.UpgradeEventTest.UpgradedEvent",
        "Elixir.EventStore.UpgradeEventTest.AnotherEvent"
      ]
      assert Enum.at(events, 1).data == %UpgradedEvent{uuid: 2, additional: "upgraded"}
    end
  end

  defp migrate(context) do
    EventStore.Migrator.migrate(fn stream ->
      Stream.map(
        stream,
        fn (event) ->
          case event.data do
            %OriginalEvent{uuid: uuid} ->
              %EventStore.RecordedEvent{event |
                event_type: "Elixir.EventStore.UpgradeEventTest.UpgradedEvent",
                data: %UpgradedEvent{uuid: uuid, additional: "upgraded"},
              }
            _ -> event
          end
        end
      )
    end)

    context
  end

  defp append_events(_context) do
    stream_uuid = UUID.uuid4()

    events = EventFactory.to_event_data([
      %AnotherEvent{uuid: 1},
      %OriginalEvent{uuid: 2},
      %AnotherEvent{uuid: 3}
    ])

    EventStore.append_to_stream(stream_uuid, 0, events)

    [stream_uuid: stream_uuid]
  end

  def pluck(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end
end
