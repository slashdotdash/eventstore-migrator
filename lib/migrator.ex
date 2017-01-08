defmodule EventStore.Migrator do
  @moduledoc """
  Migrate an event store using a copy & transform strategy
  """

  alias EventStore.Migrator.Tasks.{
    CreateTempEventsTable,
    SwitchEventsTable,
    WriteTempEvent,
  }

  defmodule State do
    defstruct [
      conn: nil,
      serializer: nil,
      next_event_id: 1,
      stream_versions: %{},
    ]
  end

  @doc """
  Migrate the event store using the given migrator function
  """
  def migrate(migrator) when is_function(migrator) do
    config = Application.get_env(:eventstore, EventStore.Storage)
    serializer = config[:serializer]

    {:ok, conn} = Postgrex.start_link(config)

    CreateTempEventsTable.execute(conn)

    EventStore.stream_all_forward()
    |> Stream.transform(%EventStore.Migrator.State{conn: conn, serializer: serializer}, fn (event, state) -> migrate(migrator, event, state) end)
    |> Stream.run

    Application.stop(:eventstore)

    # TODO: update event_id for subscriptions & snapshots

    SwitchEventsTable.execute(conn)

    Application.ensure_started(:eventstore)
  end

  defp migrate(migrator, event, %EventStore.Migrator.State{conn: conn, serializer: serializer, next_event_id: next_event_id} = state) do
    state = case migrator.(event) do
      :copy -> copy_event(event, state)
      :skip -> state
    end

    {[event], state}
  end

  defp copy_event(event, %EventStore.Migrator.State{conn: conn, serializer: serializer, next_event_id: next_event_id, stream_versions: stream_versions} = state) do
    stream_version = Map.get(stream_versions, event.stream_id, 0) + 1

    WriteTempEvent.execute(conn, event, next_event_id, stream_version, serializer)

    %EventStore.Migrator.State{state |
      next_event_id: next_event_id + 1,
      stream_versions: Map.put(stream_versions, event.stream_id, stream_version)
    }
  end
end
