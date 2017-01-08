defmodule EventStore.Migrator do
  @moduledoc """
  Migrate an event store using a copy & transform strategy
  """

  @doc """
  Migrate the event store using the given migrator function
  """
  def migrate(migrator) when is_function(migrator) do
    # begin transaction
    # - create temp events table
    # - stream events from `events` table
    #   - pass each event to `migrator` function
    #   - skip or write copied/modified event to temp events table (include original event id)
    # - update event_id for subscriptions & snapshots
    # commit transaction
  end
end
