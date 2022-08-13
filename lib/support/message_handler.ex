defmodule LiveSelect.MessageHandler do
  @moduledoc false

  alias LiveSelect.ChangeMsg

  defmodule Behaviour do
    @moduledoc false

    @callback handle(change_msg :: ChangeMsg.t(), opts :: Keyword.t()) :: any()
  end

  @behaviour Behaviour

  @impl true
  def handle(%ChangeMsg{text: text} = change_msg, opts) do
    populate_cities()

    Process.send_after(
      self(),
      {:update_live_select, change_msg, find_cities(text)},
      opts[:delay]
    )
  end

  defp populate_cities() do
    unless Process.get(:cities) do
      Process.put(
        :cities,
        Path.expand("../../assets/cities.json", __DIR__)
        |> File.read!()
        |> Jason.decode!()
      )
    end
  end

  defp find_cities(""), do: []

  defp find_cities(text) do
    Process.get(:cities)
    |> Enum.filter(fn %{"name" => name} ->
      String.contains?(String.downcase(name), String.downcase(text))
    end)
    |> Enum.map(fn %{"name" => name, "loc" => %{"coordinates" => coord}} ->
      {name, coord}
    end)
  end
end
