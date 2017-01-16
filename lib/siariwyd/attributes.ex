defmodule Siariwyd.Attributes do

  @moduledoc false

  defmacro __using__(_opts \\ []) do

    quote do

      # the name of the dictionary in the caller module
      @siariwyd_registrations :siariwyd_registrations
      @siariwyd_module_init_flag :siariwyd_module_init_flag

      @siariwyd_pipelines  %{

        registrations: [
          :bootstrap,
          :initialize,
          :register_functions,
          :finalize],

        inclusions: [:include_functions]

      }

      @siariwyd_pipelines_run [:registrations, :inclusions]

      @siariwyd_opts_keys_valid [:register, :filter, :mapper, :include, :module]
      @siariwyd_opts_keys_normalise [:register, :filter, :mapper, :include, :module]

      @siariwyd_opts_keys_pipeline [:register, :include]
      @siariwyd_opts_defaults [include: nil]

    end

  end

end
