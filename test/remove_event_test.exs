defmodule EventStore.Migrator.RemoveEventTest do
  use EventStore.Migrator.StorageCase

  alias EventStore.Migrator.EventFactory

  defmodule WantedEvent, do: defstruct [uuid: nil]
  defmodule UnwantedEvent, do: defstruct [uuid: nil]

  defmodule ASnapshot, do: defstruct [uuid: nil]

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

  describe "remove an event with all stream subscription" do
    setup [:append_events, :create_all_stream_subscription, :migrate]

    test "should copy subscription", context do
      {:ok, [subscription]} = EventStore.Migrator.Reader.subscriptions()

      assert subscription.stream_uuid == "$all"
      assert subscription.subscription_name == context[:subscription_name]
      assert subscription.last_seen_event_id == 2
      assert subscription.last_seen_stream_version == nil
    end
  end

  describe "remove an event with single stream subscription" do
    setup [:append_events, :create_single_stream_subscription, :migrate]

    test "should copy subscription", context do
      {:ok, [subscription]} = EventStore.Migrator.Reader.subscriptions()

      assert subscription.stream_uuid == context[:stream_uuid]
      assert subscription.subscription_name == context[:subscription_name]
      assert subscription.last_seen_event_id == nil
      assert subscription.last_seen_stream_version == 2
    end
  end

  describe "remove an event with a snapshot" do
    setup [:append_events, :create_snapshot, :migrate]

    test "should copy snapsot", context do
      {:ok, snapshot} = EventStore.Migrator.Reader.read_snapshot(context[:stream_uuid])

      assert snapshot.source_uuid == context[:stream_uuid]
      assert snapshot.source_version == 2
    end
  end

  defp migrate(context) do
    EventStore.Migrator.migrate(fn stream ->
      Stream.reject(
        stream,
        fn (event_data) -> event_data.event_type == "#{__MODULE__}.UnwantedEvent" end
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

  defp create_all_stream_subscription(_context) do
    subscription_name = "test-all-subscription"

    EventStore.subscribe_to_all_streams(subscription_name, self(), 0)

    [subscription_name: subscription_name]
  end

  defp create_single_stream_subscription(context) do
    subscription_name = "test-single-subscription"

    EventStore.subscribe_to_stream(context[:stream_uuid], subscription_name, self(), 0)

    [subscription_name: subscription_name]
  end

  defp create_snapshot(context) do
    EventStore.record_snapshot(%EventStore.Snapshots.SnapshotData{
      source_uuid: context[:stream_uuid],
      source_version: 0,
      source_type: "Elixir.EventStore.RemoveEventTest.ASnapshot",
      data: "{\"uuid\":1}",
      metadata: "{}",
      created_at: DateTime.utc_now |> DateTime.to_naive,
    })

    []
  end

  def pluck(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end
end
