defmodule LiveSelect.ClassUtil do
  @moduledoc false

  @doc ~S"""
  iex> extend("bg-white text-yellow", "p-2")
  "bg-white text-yellow p-2"

  iex> extend("bg-white text-yellow", "bg-white")
  "bg-white text-yellow"

  iex> extend("bg-white text-yellow", "!text-yellow text-black")
  "bg-white text-black"

  iex> extend("bg-white text-yellow", "!text-yellow text-black !bg-white")
  "text-black"

  iex> extend("bg-white text-yellow", "!text-yellow !bg-white")
  ""

  iex> extend("bg-white text-yellow", "")
  "bg-white text-yellow"

  iex> extend("", "")
  ""
  """
  @spec extend(String.t(), String.t()) :: String.t()
  def extend(base, extend) do
    base_classes =
      String.split(base)
      |> Enum.uniq()

    {remove, add} =
      extend
      |> String.split()
      |> Enum.split_with(&String.starts_with?(&1, "!"))

    add =
      add
      |> Enum.reject(&(&1 in base_classes))
      |> Enum.uniq()

    remove =
      remove
      |> Enum.map(&String.trim_leading(&1, "!"))
      |> Enum.uniq()

    ((base_classes -- remove) ++ add)
    |> Enum.join(" ")
  end
end
