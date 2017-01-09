defmodule EventStore.Migrator do
  @moduledoc """
  Migrate an event store using a copy & transform strategy
  """

  alias EventStore.Migrator.Tasks.{
    RemoveEmptyStreams,
    SetLastSeenEvent,
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
    source_config = Application.get_env(:eventstore, EventStore.Storage)
    target_config = Application.get_env(:eventstore_migrator, EventStore.Migrator)

    migrate(source_config, target_config, migrator)
  end

  @doc """
  Migrate the event store using the given migrator function and source and target event store configurations
  """
  def migrate(source, target, migrator) when is_function(migrator) do
    source_config = parse_config(source)
    target_config = parse_config(target)

    do_migrate(source_config, target_config, migrator)
  end

  defp do_migrate(%Config{} = source, %Config{} = target, migrator) when is_function(migrator) do
    EventStore.Storage.Initializer.run!(target.conn)

    copy_table(source, target, "snapshots")
    copy_table(source, target, "streams")
    copy_table(source, target, "subscriptions")

    migrate_events(migrator, target)

    RemoveEmptyStreams.execute(target.conn)
    SetLastSeenEvent.execute(target.conn)
  end

  defp parse_config(config) do
    {:ok, conn} = Postgrex.start_link(config)

    %Config{
      config: config,
      conn: conn,
      serializer: config[:serializer]
    }
  end

  defp copy_table(%Config{conn: source}, %Config{conn: target}, table) do
    TableCopier.execute(source, target, table)
  end

  # migrate events between source and target using a stream passed to a migrator function that can modify any events
  defp migrate_events(migrator, %Config{} = target) do
    StreamAllEvents.execute()
    |> migrator.()
    |> WriteEvents.execute(target)
    |> Stream.run
  end
end
