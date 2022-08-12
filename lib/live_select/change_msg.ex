defmodule LiveSelect.ChangeMsg do
  @moduledoc "LiveSelect.ChangeMsg"

  @typedoc ~S"Message sent by `LiveSelect` components in response to text entered by the user in the text input field"

  @type t :: %__MODULE__{
          id: term(),
          field: atom(),
          text: String.t(),
          module: module()
        }

  @enforce_keys [:id, :field, :text, :module]
  defstruct [:id, :field, :text, :module]
end
