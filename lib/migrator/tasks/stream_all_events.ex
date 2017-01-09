defmodule EventStore.Migrator.Tasks.StreamAllEvents do
  def execute() do
    EventStore.stream_all_forward()
  end
end
