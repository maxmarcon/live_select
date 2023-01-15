defmodule LiveSelect.ChangeMsgHandler do
  @moduledoc false

  alias LiveSelect.ChangeMsg
  alias LiveSelect.CityFinder

  defmodule Behaviour do
    @moduledoc false

    @callback handle(change_msg :: ChangeMsg.t(), opts :: Keyword.t()) :: any()
  end

  @behaviour Behaviour

  @impl true
  def handle(%ChangeMsg{text: text} = change_msg, opts) do
    result = GenServer.call(CityFinder, {:find, text})

    Process.send_after(
      self(),
      {:update_live_select, change_msg, result},
      opts[:delay]
    )
  end
end
