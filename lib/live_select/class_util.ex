defmodule LiveSelect.ClassUtil do
  @moduledoc false

  @doc ~S"""
  iex> extend(~W(bg-white text-yellow), ~W(p-2))
  ~W(bg-white text-yellow p-2)

  iex> extend(~W(bg-white text-yellow), ~W(bg-white))
  ~W(bg-white text-yellow)

  iex> extend(~W(bg-white text-yellow), ~W(!text-yellow text-black))
  ~W(bg-white text-black)

  iex> extend(~W(bg-white text-yellow), ~W(!text-yellow text-black !bg-white))
  ~W(text-black)

  iex> extend(~W(bg-white text-yellow), ~W(!text-yellow !bg-white))
  []

  iex> extend(~W(bg-white text-yellow), [])
  ~W(bg-white text-yellow)

  iex> extend([], [])
  []
  """
  @spec extend([String.t()], [String.t()]) :: [String.t()]
  def extend(base, extend) when is_list(base) and is_list(extend) do
    base_classes =
      Enum.uniq(base)
      |> Enum.filter(& &1)

    {remove, add} =
      extend
      |> Enum.filter(& &1)
      |> Enum.split_with(&String.starts_with?(&1, "!"))

    add =
      add
      |> Enum.reject(&(&1 in base_classes))
      |> Enum.uniq()

    remove =
      remove
      |> Enum.map(&String.trim_leading(&1, "!"))
      |> Enum.uniq()

    (base_classes -- remove) ++ add
  end
end
