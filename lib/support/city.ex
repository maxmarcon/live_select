defmodule LiveSelect.City do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:name)
    field(:pos, {:array, :float})
  end

  def changeset(%__MODULE__{} = schema \\ %__MODULE__{}, params) do
    cast(schema, params, [:name, :pos])
  end
end
