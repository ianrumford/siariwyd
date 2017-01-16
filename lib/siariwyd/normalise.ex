defmodule Siariwyd.Normalise do

  @moduledoc false

  require Logger

  defp maybe_ast_realise(value, opts \\ [])

  defp maybe_ast_realise(value, _opts)
  when is_atom(value)
  or is_bitstring(value)
  or is_boolean(value)
  or is_function(value)
  or is_map(value)
  or is_number(value)
  or is_pid(value)
  or is_port(value)
  or is_reference(value) do
    value
  end

  # quoted module attribute - leave alone
  defp maybe_ast_realise({:@, _, [{attr_name, _, _}]} = value, _opts) when is_atom(attr_name) do

    value

  end

  # list with maybe quoted elements
  defp maybe_ast_realise(value, _opts) when is_list(value) do
    value |> Enum.map(fn v -> v |> maybe_ast_realise end)
  end

  # quoted map
  defp maybe_ast_realise({:%{}, _, args} = _value, _opts) do

    args
    |> Stream.map(fn {k,v} ->
      {k |> maybe_ast_realise, v |> maybe_ast_realise}
    end)
    |> Enum.into(%{})

  end

  # quoted tuple
  defp maybe_ast_realise({:{}, _, args} = _value, _opts) do

    args
    |> Enum.map(fn v -> v |> maybe_ast_realise end)
    |> List.to_tuple

  end

  defp maybe_ast_realise({_, _, _} = value, _opts) do
    case value |> Macro.validate do
      :ok -> value |> Code.eval_quoted([], __ENV__) |> elem(0)
      _ -> value
    end
  end

  # default
  defp maybe_ast_realise(value, _opts) do
    value
  end

  def maybe_ast_realise_fun(value)

  def maybe_ast_realise_fun(nil) do
    nil
  end

  def maybe_ast_realise_fun(value) when is_tuple(value) do
    value
    |> maybe_ast_realise
    |> maybe_ast_realise_fun
  end

  def maybe_ast_realise_fun(value) when is_function(value) do
    value
  end

  def maybe_ast_realise_fun!(value)

  def maybe_ast_realise_fun!(value) when is_function(value) do
    value
  end

  def maybe_ast_realise_fun!(value) do
    message = "maybe_ast_realise_fun!: value not a function #{inspect value}"
    Logger.error message
    raise ArgumentError, message: message
  end

  def maybe_ast_realise_module(value)

  def maybe_ast_realise_module(nil) do
    nil
  end

  def maybe_ast_realise_module(value) when is_tuple(value) do
    value
    |> maybe_ast_realise
    |> maybe_ast_realise_module
  end

  def maybe_ast_realise_module(value) when is_atom(value) do
    value
  end

  def maybe_ast_realise_module!(value)

  def maybe_ast_realise_module!(value) when is_atom(value) do
    value
  end

  def maybe_ast_realise_module!(value) do
    message = "maybe_ast_realise_module!: value not a module #{inspect value}"
    Logger.error message
    raise ArgumentError, message: message
  end

  def normalise_function_names(names) do
    names
    |> List.wrap
    |> Enum.reject(&is_nil/1)
  end

  def validate_function_names!(names) do
    names = names |> normalise_function_names
    true = names |> Enum.all?(fn name -> is_atom(name) end)
    names
  end

end
