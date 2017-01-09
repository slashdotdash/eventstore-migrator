defmodule EventStore.Migrator do
  @moduledoc """
  Migrate an event store using a copy & transform strategy
  """

  alias EventStore.Migrator.Tasks.{
    CreateTempEventsTable,
    StreamAllEvents,
    SwitchEventsTable,
    WriteTempEvent,
  }

  @doc """
  Migrate the event store using the given migrator function
  """
  def migrate(migrator) when is_function(migrator) do
    config = Application.get_env(:eventstore, EventStore.Storage)
    serializer = config[:serializer]

    {:ok, conn} = Postgrex.start_link(config)

    CreateTempEventsTable.execute(conn)

    StreamAllEvents.execute()
    |> migrator.()
    |> WriteTempEvent.execute(conn, serializer)
    |> Stream.run

    Application.stop(:eventstore)

    # TODO: update event_id for subscriptions & snapshots

    SwitchEventsTable.execute(conn)

    Application.ensure_started(:eventstore)
  end
end
