defmodule LiveSelect.DecodeTest do
  @moduledoc false

  use ExUnit.Case, async: true

  describe "decode/1" do
    test "decodes nil to empty list" do
      assert LiveSelect.decode(nil) == []
    end

    test "decodes empty string to nil" do
      assert LiveSelect.decode("") == nil
    end

    test "decodes a JSON-encoded map" do
      assert LiveSelect.decode(~s({"name":"Berlin","pos":[13.41,52.52]})) ==
               %{"name" => "Berlin", "pos" => [13.41, 52.52]}
    end

    test "decodes a list of JSON-encoded maps" do
      assert LiveSelect.decode([
               ~s({"name":"Berlin"}),
               ~s({"name":"Rome"})
             ]) == [
               %{"name" => "Berlin"},
               %{"name" => "Rome"}
             ]
    end

    test "returns plain string as-is when it's not valid JSON" do
      assert LiveSelect.decode("Glon") == "Glon"
    end

    test "returns string with special characters as-is when not valid JSON" do
      assert LiveSelect.decode("São Paulo") == "São Paulo"
    end

    test "returns list elements as-is when they are not valid JSON" do
      assert LiveSelect.decode(["Berlin", "Rome"]) == ["Berlin", "Rome"]
    end
  end
end
