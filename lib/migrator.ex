defmodule EventStore.Migrator do
  @moduledoc """
  Migrate an event store using a copy & transform strategy
  """

  alias EventStore.Migrator.Tasks.{
    RemoveEmptyStreams,
    StreamAllEvents,
    TableCopier,
    WriteEvents,
  }

  defmodule Config do
    defstruct [config: nil, conn: nil, serializer: nil]
  end

  alias EventStore.Migrator.Config

  @doc """
  Migrate the event store using the given migrator function
  """
  def migrate(migrator) when is_function(migrator) do
    source = parse_config(:eventstore, EventStore.Storage)
    target = parse_config(:eventstore_migrator, EventStore.Migrator)

    EventStore.Storage.Initializer.run!(target.conn)

    copy_table(source, target, "snapshots")
    copy_table(source, target, "streams")
    copy_table(source, target, "subscriptions")

    migrate(migrator, source, target)

    RemoveEmptyStreams.execute(target.conn)
  end

  defp parse_config(app, key) do
    config = Application.get_env(app, key)
    serializer = config[:serializer]

    {:ok, conn} = Postgrex.start_link(config)

    %Config{
      config: config,
      conn: conn,
      serializer: serializer
    }
  end

  defp copy_table(%Config{conn: source}, %Config{conn: target}, table) do
    TableCopier.execute(source, target, table)
  end

  # migrate events between source and target using a stream passed to a migrator function that can modify any events
  defp migrate(migrator, source, target) do
    StreamAllEvents.execute()
    |> migrator.()
    |> WriteEvents.execute(target)
    |> Stream.run
  end
end
