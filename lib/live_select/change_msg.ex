defmodule LiveSelect.ChangeMsg do
  @moduledoc ~S"Message sent by `LiveSelect` components when the user has edited the search field"

  @type t :: %__MODULE__{
          id: term(),
          field: atom(),
          text: String.t(),
          module: module()
        }

  @enforce_keys [:id, :field, :text, :module]
  defstruct [:id, :field, :text, :module]
end
