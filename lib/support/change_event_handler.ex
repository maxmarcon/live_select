defmodule LiveSelect.ChangeEventHandler do
  @moduledoc false

  alias LiveSelect.CityFinder

  defmodule Behaviour do
    @moduledoc false

    @callback handle(params :: %{String.t() => String.t()}, opts :: Keyword.t()) :: any()
  end

  @behaviour Behaviour

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
