defmodule EventStore.Migrator.EventFactory do
  def to_event_data(events) do
    correlation_id = UUID.uuid4()

    Enum.map(events, fn event -> to_event_data(event, correlation_id) end)
  end

  def to_event_data(event, correlation_id) do  
    %EventStore.EventData{
      correlation_id: correlation_id,
      event_type: Atom.to_string(event.__struct__),
      data: event,
      metadata: %{},
    }
  end
end
