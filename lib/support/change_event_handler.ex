defmodule LiveSelect.ChangeEventHandler do
  @moduledoc false

  alias LiveSelect.CityFinder

  @callback handle(params :: %{String.t() => String.t()}, opts :: Keyword.t()) :: any()

  @behaviour __MODULE__

  @impl true
  def handle(%{"text" => text} = params, opts) do
    result = GenServer.call(CityFinder, {:find, text})

    Process.send_after(
      self(),
      {:update_live_select, params, result},
      opts[:delay]
    )
  end
end
