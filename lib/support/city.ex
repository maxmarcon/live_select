defmodule LiveSelect.City do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:name)
    field(:pos, {:array, :float})
  end

  def changeset(%__MODULE__{} = schema \\ %__MODULE__{}, params) do
    cast(schema, params, [:id, :name, :pos])
  end
end
