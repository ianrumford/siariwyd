defmodule Siariwyd.Accessors do

  @moduledoc false

  use Siariwyd.Attributes

  def module_init_flag_get(module) do
    module |> Module.get_attribute(@siariwyd_module_init_flag)
  end

  def module_init_flag_put(module, init_flag) do
    module |> Module.put_attribute(@siariwyd_module_init_flag, init_flag)
  end

  def module_init_flag_register(module, opts \\ []) do
    module |> Module.register_attribute(@siariwyd_module_init_flag, opts)
  end

  def compiled_module_registrations_get(module) do
    module.__info__(:attributes)
    |> Keyword.get(@siariwyd_registrations)
    |> List.first
  end

  def module_registrations_get(module) do
    module |> Module.get_attribute(@siariwyd_registrations)
  end

  def module_registrations_fetch!(module) do

    case module |> module_registrations_get do

      x when is_map(x) -> x

      _ ->

        # must exists
        raise ArgumentError, message: "Siariwyd:on_definition registrations #{@siariwyd_registrations} does not exist"

    end

  end

  def module_registrations_put(module, registrations) do

    :ok = module |> Module.put_attribute(@siariwyd_registrations, registrations)

    module
  end

  def module_registrations_register(module) do

    :ok = module
    |> Module.register_attribute(@siariwyd_registrations, accumulate: false, persist: true)
    module
  end

  def module_registrations_merge(module, registrations) do

    module
    |> module_registrations_get
    |> Map.merge(registrations)
    |> fn registrations ->
      module |> module_registrations_put(registrations)
    end.()

    module
  end

  def spec_registrations_get(spec, default \\ []) do
    spec |> Map.get(:registrations, default)
  end

  def spec_registrations_put(spec, value) do
    spec |> Map.put(:registrations, value)
  end

  def spec_inclusions_get(spec, default \\ []) do
    spec |> Map.get(:inclusions, default)
  end

  def spec_inclusions_put(spec, value) do
    spec |> Map.put(:inclusions, value)
  end

  def spec_pipelines_get(spec, default) do
    spec |> Map.get(:pipelines, default)
  end

  def spec_asts_get(spec, default \\ %{}) do
    spec |> Map.get(:asts, default)
  end

  def spec_asts_put(spec, value) do
    spec |> Map.put(:asts, value)
  end

  def spec_asts_verb_get(spec, verb, default \\ nil) do
    spec |> spec_asts_get |> Map.get(verb, default)
  end

  def spec_asts_verb_put(spec, verb, ast) do
    asts = spec |> spec_asts_get |> Map.put(verb, ast)
    spec |> spec_asts_put(asts)
  end

  def spec_module_put(spec, value) do
    spec |> Map.put(:module, value)
  end

  def spec_filter_get(spec, default) do
    spec |> Map.get(:filter, default)
  end

  def spec_filter_put(spec, value) do
    spec |> Map.put(:filter, value)
  end

  def spec_mapper_get(spec, default) do
    spec |> Map.get(:mapper, default)
  end

  def spec_mapper_put(spec, value) do
    spec |> Map.put(:mapper, value)
  end

  def spec_opts_put(spec, value) do
    spec |> Map.put(:opts, value)
  end

end
