defmodule EventStore.Migrator.MigrateSerializationFormatTest do
  use EventStore.Migrator.StorageCase

  alias EventStore.Migrator.EventFactory

  defmodule AnEvent, do: defstruct [uuid: nil]
  defmodule AnotherEvent, do: defstruct [uuid: nil]

  describe "upgrade an event" do
    setup [:append_events, :migrate]

    test "should migrate all events using new serialization format" do
      {:ok, events} = EventStore.Migrator.Reader.read_migrated_events()

      assert length(events) == 3
      assert pluck(events, :event_id) == [1, 2, 3]
      assert pluck(events, :stream_version) == [1, 2, 3]
      assert pluck(events, :event_type) == [
        "#{__MODULE__}.AnEvent",
        "#{__MODULE__}.AnotherEvent",
        "#{__MODULE__}.AnotherEvent"
      ]
      assert Enum.at(events, 0).data == :erlang.term_to_binary(%AnEvent{uuid: 1})
    end

    test "should copy stream", context do
      {:ok, stream_id, stream_version} = EventStore.Migrator.Reader.stream_info(context[:stream_uuid])

      assert stream_id == 1
      assert stream_version == 3
    end
  end

  defp migrate(context) do
    source_config = Application.get_env(:eventstore, EventStore.Storage)
    target_config = Application.get_env(:eventstore_migrator, EventStore.Migrator)

    # switch serializer from JSON to Erlang term format
    target_config = Keyword.put(target_config, :serializer, EventStore.TermSerializer)

    EventStore.Migrator.migrate(source_config, target_config, fn stream -> stream end)

    context
  end

  defp append_events(_context) do
    stream_uuid = UUID.uuid4()

    events = EventFactory.to_event_data([
      %AnEvent{uuid: 1},
      %AnotherEvent{uuid: 2},
      %AnotherEvent{uuid: 3}
    ])

    EventStore.append_to_stream(stream_uuid, 0, events)

    [stream_uuid: stream_uuid]
  end

  def pluck(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end
end
