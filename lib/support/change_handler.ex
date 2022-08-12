defmodule LiveSelect.ChangeHandler do
  @moduledoc false

  defmodule Behaviour do
    @moduledoc false

    @callback handle_change(search_term :: String.t()) :: list()
  end

  @behaviour Behaviour

  @impl true
  def handle_change(search_term) do
    populate_cities()

    find_cities(search_term)
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
