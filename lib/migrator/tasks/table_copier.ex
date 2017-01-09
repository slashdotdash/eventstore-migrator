defmodule EventStore.Migrator.Tasks.TableCopier do
  def execute(source, target, table) do
    Postgrex.transaction(source, fn source_conn ->
      Postgrex.transaction(target, fn target_conn ->
        copy(source_conn, target_conn, table)
      end)
    end)
  end

  defp copy(source_conn, target_conn, table) do
    query = Postgrex.prepare!(source_conn, "", "COPY #{table} TO STDOUT")
    source_stream = Postgrex.stream(source_conn, query, [])
    result_to_iodata = fn %Postgrex.Result{rows: rows} -> rows end

    target_stream = Postgrex.stream(target_conn, "COPY #{table} FROM STDIN", [])

    Enum.into(source_stream, target_stream, result_to_iodata)
  end
end
