ExUnit.start()

defmodule SiariwydHelpersTest do

  def module_registrations_get(module) do

    module.__info__(:attributes)
    |> Keyword.get(:siariwyd_registrations)
    |> List.first

  end

  def module_registrations_keys_get(module) do
    module
    |> module_registrations_get
    |> Map.keys
  end

  def module_registrations_keys_v_specs_count_get(module) do
    module
    |> module_registrations_get
    |> Enum.map(fn {key, specs} -> {key, specs |> length} end)
  end

  def module_functions_get(module) do
    module.__info__(:functions)
    |> Keyword.keys
    |> Enum.uniq
  end

end

