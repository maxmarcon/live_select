defmodule LiveSelect.CityFinder do
  @moduledoc false

  use GenServer

  alias LiveSelect.City

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    cities =
      Application.app_dir(:live_select, Path.join("priv", "cities.json"))
      |> File.read!()
      |> Jason.decode!()

    {:ok, cities}
  end

  @impl true
  def handle_call({:find, ""}, _from, cities), do: {:reply, [], cities}

  @impl true
  def handle_call({:find, term}, _from, cities) do
    result =
      cities
      |> Enum.filter(fn %{"name" => name} ->
        String.contains?(String.downcase(name), String.downcase(term))
      end)
      |> Enum.map(fn %{"name" => name, "loc" => %{"coordinates" => coord}} ->
        %{name: name, pos: coord}
      end)
      |> Enum.map(&struct!(City, &1))

    {:reply, result, cities}
  end
end
