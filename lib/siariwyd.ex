defmodule Siariwyd do

  @moduledoc ~S"""
  A module for sharing and reusing callback functions.

  The most obvious use case is the callback functions of
  `GenServer` i.e. `handle_code/3`, `handle_cast/2` and
  `handle_info/2`.

  Callback function *sources* have to be compiled together in the
  callback module to enable multiple implementations of the same
  callback to be found by pattern matching.

  Although targetting `GenServer` callbacks, `Siariwyd` can be used to
  share any function's implementations (callback or otherwise) that
  must be compiled together.

  `Siariwyd` enables one or more implementations of a function to be
  *register*-ed in one or more **donor** modules and selectively
  *include*-d into a **recipient** (e.g. callback) module at
  compilation time.

  ## Example

  Below are two example `GenServer` **donor** modules, one (**DonorA**)
  with one `handle_call/3` and one `handle_cast/2`, and the other
  (**DonorB**) with one `handle_call/3` implementations:

      defmodule DonorA do

        use GenServer

        Use Siariwyd, register: [:handle_call, :handle_cast, :handle_info]

        def handle_call({:donor_a_call1, value}, _fromref, state) do
          {:reply, value, state}
        end

        def handle_cast({:donor_a_cast3, value}, state) do
          {:noreply, state}
        end

      end

      defmodule DonorB do

        use GenServer

        Use Siariwyd, register: [:handle_call, :handle_cast, :handle_info]

        def handle_call({:donor_b_call1, value}, _fromref, state) do
          {:reply, value, state}
        end

      end

  The *use* call:

        use Siariwyd, register: [:handle_call, :handle_cast, :handle_info]

  causes *all* of the `handle_call/3`, `handle_cast/2` and `handle_info/2`
  definitions found in the **DonorA** and **DonorB** modules to be saved in
  each module's compiled (BEAM) file.

  Siariwyd does not insist on finding implementations for
  *register*-ed functions - there are e.g. no `handle_info/1`
  functions in either of the donor modules.

  The *register*-ed implementations can be *include*-d into a
  **recipient** module.  Again, if no implementations are found in the
  donor module(s), the callback is ignored.

      defmodule Recipient1 do

        use GenServer

        # <handle calls start here>

        use Siariwyd, module: DonorA, include: :handle_call
        use Siariwyd, module: DonorB, include: :handle_call

        def handle_call({:recipient_call1, value}, _fromref, state) do
          {:reply, value, state}
        end

        # <handle calls finish here>

        # <handle casts start here>

        use Siariwyd, module: DonorA, include: :handle_cast

        def handle_call({:recipient_cast3, value}, _fromref, state) do
          {:reply, state}
        end

        # <handle casts finish here>

        # <handle_infos start here>

        # no definitions will be found and these uses ignored
        use Siariwyd, module: DonorA, include: :handle_info
        use Siariwyd, module: DonorB, include: :handle_info

        # <handle_infos finish here>

      end

  Implementations are *include*-d first in the order of the *use*s in
  the recipient module and then the order in which they appear in
  the donor module(s).

  ## A Function's Implementation Definition

  A function's implementation definition is a map holding
  most of the arguments passed to `Module` compiler callback
  @on_definition, together with only the `file` and `line` fields from the
  `env` argument.

  It also has a key `:ast` holding the full implementation of the
  function; the value of the `:ast` key is *include*d when no `mapper`
  (see later) is given.

  The complete list of keys are:

  * `:name` the name of the function (e.g. *handle_call*)
  * `:kind` :def, :defp, :defmacro, or :defmacrop
  * `:args` the list of quoted arguments
  * `:guards` list of quoted guards
  * `:body` the quoted function body
  * `:file` the source file of the function
  * `:line` the source file line number of the function
  * `:ast` the complete ast of the function

  ## Default is to Include all Implementations for all Registered Functions

  If neither `:include` nor `:register` options are given, the default is
  to *include* **all** implementations for **all** registered functions in
  the donor module. e.g.

      use Siariwyd, module: DonorA

  ## Filtering the Included Implementations

  A `:filter` function (`filter/1`) can be given to refine the
  selection of the wanted implementations.

  The `:filter` function is used with `Enum.filter/2` and is passed a
  function implementation definition.

  For example this function would select only `handle_call/3` definitions:

      use Siariwyd, module: DonorX,
      filter: fn
        %{name: :handle_call} -> true
        _ -> false
      end

  A `filter/1` function is applied **after** the implementations to
  *include* have been selected (i.e. the `:include` option functions or all
  implementations for all registered functions).

  ## Transforming (mapping) the Included Definitions

  A `:mapper` function (`mapper/1`) can be given to transform the
  wanted implementations.

  The `mapper/1` is passed a function's implementation definition
  and must return a definition, normally with the `:ast` for the
  complete implementation updated.

  Siariwyd provides a convenience function
  `Siariwyd.reconstruct_function/1` to rebuild the `:ast` from the
  (updated) definition.

  The example below shows how a `handle_info/2` responding to
  *:process_message* could be changed to respond to *:analyse_message*

      use Siariwyd, module: DonorY,
      mapper: fn

        # select handle_info definition
        %{name: :handle_info, args: args} = implementation_definition ->

        # args is the list of quoted arguments to the implementation
        # e.g. handle_info(:process_message, state)

        [arg | rest_args] = args

        case arg do
          :process_message ->

            # change the args to respond to :analyse_message
            implementation_definition
            |> Map.put(:args, [:analyse_message | rest_args])
            # reconstruct the complete implementation using the convenience function
            |> Siariwyd.reconstruct_function

          # nothing to do
          _ -> implementation_definition
        end

        # passthru
        implementation_definition -> implementation_definition

      end

  A `mapper/1` is applied **after** any `filter/1`.
  """

  use Siariwyd.Attributes
  import Siariwyd.Accessors
  import Siariwyd.Normalise

  @typedoc "The names of the functions to register or include."
  @type name :: atom
  @type names :: name | [name]

  @typedoc "Something that can be unquoted"
  @type unquotable :: Macro.t

  @typedoc "Maybe quoted module"
  @type maybe_quoted_module :: module | unquotable

  @type kind :: :def | :defp | :defmacro | :defmacrop

  @typedoc "The function definition is derived from @on_definition arguments"
  @type function_definition :: %{
    name: :atom,
    kind: kind,
    args: [Macro.t],
    guards: [Macro.t],
    body: Macro.t,
    file: binary,
    line: integer,
    ast: Macro.t
  }

  @typedoc "Maybe quoted filter fun"
  @type maybe_quoted_filter_fun ::unquotable | ({name, function_definition} -> as_boolean(term))

  @typedoc "Maybe quoted mapper fun"
  @type maybe_quoted_mapper_fun :: unquotable | ({name, function_definition} -> unquotable)

  @typedoc "The opts for the register action"
  @type register_opt ::
  {:register, names} |
  {:module, maybe_quoted_module}
  @type register_opts :: [register_opt]

  @typedoc "The opts for the include action"
  @type include_opt ::
  {:include, names} |
  {:filter, maybe_quoted_filter_fun} |
  {:mapper, maybe_quoted_mapper_fun} |
  {:module, maybe_quoted_module}
  @type include_opts :: [include_opt]

  @typedoc "The options passed to the use call."
  @type use_option ::
  {:include, names} |
  {:register, names} |
  {:filter, maybe_quoted_filter_fun} |
  {:mapper, maybe_quoted_mapper_fun} |
  {:module, module}

  @type use_options :: [use_option]

  @doc ~S"""
  This convenenience function completely rebuilds the function's implementation (an ast).

  It is intended for use in `mapper/1` functions.

  Its takes the function's  definition as argument, reconstructs
  the implementation's ast, saves the ast under the definition's `:ast`
  key, and returns the updated definition.
  """

  @spec reconstruct_function(function_definition) :: function_definition
  def reconstruct_function(definition) when is_map(definition) do

    name = definition.name

    # reconstruct the complete function ast
    function_ast = quote do
      unquote(definition.kind)(unquote(name)(unquote_splicing(definition.args))) do
        unquote(definition.body)
      end
    end

    guards = definition.guards

    # don't know to to get guards applied using quote / unquote
    # i.e. right syntax with guards
    function_ast =
      case guards do

        [] -> function_ast

        _ ->

          # need to add the guard clauses
          function_ast
          |> Macro.postwalk(
          fn

          # fun name + args ast
          {^name, _ctx, _args} = snippet ->

             # build the guard (when)  clause

            {:when, [], [snippet | guards]}

            x -> x

          end)

      end

    definition |> Map.put(:ast, function_ast)

  end

  @doc false
  def on_definition(env, kind, name, args, guards, body) do

    env_module = env.module

    # get the map of wanted registrations
    registrations = env_module |> module_registrations_fetch!

    # is this function registered?  If not ignore
    case registrations |> Map.has_key?(name) do

      true ->

        # recreate the complete ast
        definition = %{
        name: name,
        kind: kind,
        args: args,
        guards: guards,
        body: body,
        line: env.line,
        file: env.file,
        # satisfy type spec
        ast: nil}
        |> reconstruct_function

        # add in order seen
        definitions = (registrations |> Map.fetch!(name)) ++ [definition]

        # update registrations
        registrations = registrations |> Map.put(name, definitions)

        # update the module's registrations attribute
        env_module |> module_registrations_put(registrations)

       # not a registered function - nothing to do
       _ ->

        registrations

    end

  end

  @doc false
  def spec_run_action(verb, spec)

  @doc false
  def spec_run_action(:bootstrap = verb, %{caller_module: module} = spec) do

    ast = quote do
      # using persist stops the compiler warning if the attribute is
      # not used again i.e by a subsequent call to use
     unquote(module) |> Siariwyd.Accessors.module_init_flag_register(persist: true)
    end

    spec |> spec_asts_verb_put(verb, ast)

  end

  @doc false
  def spec_run_action(:initialize = verb, %{caller_module: module} = spec) do

    initial_registrations_ast = %{}
    # need to escape!
    |> Macro.escape

    ast =
      quote do

      # has module already been initialized?
      case unquote(module) |> Siariwyd.Accessors.module_init_flag_get do

        flag when flag in [nil, false] ->

          case unquote(module) |> Siariwyd.Accessors.module_registrations_get do

            x when x in [nil, false]  ->

              # create the persistent registrations attribute
              unquote(module)
              |> Siariwyd.Accessors.module_registrations_register
              # pre-create empty registrations
              |> Siariwyd.Accessors.module_registrations_put(unquote(initial_registrations_ast))

              # register the on_definition callback
              @on_definition {Siariwyd, :on_definition}

            _ ->

              nil

          end

          # already initialized
          _ -> nil

      end

    end

    spec |> spec_asts_verb_put(verb, ast)

  end

  @doc false
  def spec_run_action(:finalize = verb, %{caller_module: module} = spec) do

    ast = quote do
      unquote(module) |> Siariwyd.Accessors.module_init_flag_put(true)
    end

    spec |> spec_asts_verb_put(verb, ast)

  end

  @doc false
  def spec_run_action(:register_functions = verb, %{caller_module: module} = spec) do

    dictionary_names = spec |> spec_registrations_get

    ast =
      case dictionary_names |> length do

        # none
        0 -> nil

        _ ->

          quote do

            # create the new registrations map
            registrations = unquote(dictionary_names)
            |> Enum.map(fn name -> {name, []} end)
            |> Enum.into(%{})

            # merge with existing registrations for *same* module
            unquote(module) |> Siariwyd.Accessors.module_registrations_merge(registrations)

          end
      end

    spec |> spec_asts_verb_put(verb, ast)

  end

  @doc false
  def spec_run_action(:include_functions = verb, %{module: module} = spec) do

    registrations = module |> compiled_module_registrations_get

    includes = spec |> spec_inclusions_get
    |> case do

         # if no explicit includes, take all registered functions
         [] -> registrations |> Map.keys

         x -> x

       end

    filter_fun = spec |> spec_filter_get(&(&1))

    mapper_fun = spec |> spec_mapper_get(&(&1))

    asts = includes
    |> Enum.flat_map(fn include -> registrations |> Map.get(include, []) end)
    # apply filter
    |> Enum.filter(filter_fun)
    # apply the mapper
    |> Enum.map(mapper_fun)
    |> Enum.reject(&is_nil/1)
    # extract the asts
    |> Enum.map(fn %{ast: ast} -> ast end)

    spec |> spec_asts_verb_put(verb, asts)

  end

  defp spec_opts_normalise(:register, %{opts: opts} = spec) do

    case opts |> Keyword.has_key?(:register) do

      true ->

        spec
        |> spec_registrations_put(validate_function_names!(Keyword.fetch!(opts, :register)))

        _ -> spec

    end

  end

  defp spec_opts_normalise(:include, %{opts: opts} = spec) do

    case opts |> Keyword.has_key?(:include) do

      true ->

        spec
        |> spec_inclusions_put(validate_function_names!(Keyword.fetch!(opts, :include)))

      #_ -> []
      _ -> spec

    end

  end

  defp spec_opts_normalise(:filter, %{opts: opts} = spec) do

    case opts |> Keyword.has_key?(:filter) do

      # has a filter - need to ensure a usable un
      true ->

        filter = opts
        |> Keyword.fetch!(:filter)
        |> maybe_ast_realise_fun

        spec |> spec_filter_put(filter)

        # no filter => nothing to do
        _ -> spec

    end

  end

  defp spec_opts_normalise(:mapper, %{opts: opts} = spec) do

    case opts |> Keyword.has_key?(:mapper) do

      # has a mapper - need to ensure a usable un
      true ->

        mapper = opts
        |> Keyword.fetch!(:mapper)
        |> maybe_ast_realise_fun

        spec |> spec_mapper_put(mapper)

        # no mapper => nothing to do
        _ -> spec

    end

  end

  defp spec_opts_normalise(:module, %{opts: opts} = spec) do

    case opts |> Keyword.has_key?(:module) do

      # has a module - need to ensure a usable form
      true ->

        module = opts
        |> Keyword.fetch!(:module)
        |> maybe_ast_realise_module

        spec |> spec_module_put(module)

        # no module => nothing to do
        _ -> spec

    end

  end

  defp spec_normalise_opts(%{opts: opts} = spec) do

    opts
    |> Keyword.keys
    |> Kernel.--(@siariwyd_opts_keys_valid)
    |> case do

         [] -> nil

         unknown_keys ->

           raise ArgumentError, message:
           "Siariwyd: unknown opts keys: #{inspect unknown_keys}"

       end

    # at least one "pipeline" key?
    opts =
      case opts |> Keyword.take(@siariwyd_opts_keys_pipeline) do

        # nope - add defaults
        [] ->

           # add defaults
           @siariwyd_opts_defaults |> Keyword.merge(opts)

         # has a pipeline key
         _ -> opts
      end

    spec = spec |> spec_opts_put(opts)

    @siariwyd_opts_keys_normalise
    |> Enum.reduce(spec, fn verb, spec ->

      verb
      |> spec_opts_normalise(spec)

    end)

  end

  defp spec_normalise(spec) do

    spec
    |> spec_normalise_opts

  end

  defp spec_find_pipelines(spec) do

    spec
    |> spec_pipelines_get(@siariwyd_pipelines_run)
    |> Enum.map(fn pipeline ->

      case spec |> Map.has_key?(pipeline) do

        true ->

          value = @siariwyd_pipelines
          |> Map.fetch!(pipeline)
          |> List.wrap

          {pipeline, value}

        _ -> nil

      end

    end)
    |> Enum.reject(&is_nil/1)

  end

  @doc false
  def spec_run_pipelines(spec) do

    spec = spec
    |> spec_normalise

    pipelines = spec
    |> spec_find_pipelines

    spec = pipelines
    |> Enum.reduce(spec,
      fn {_pipeline, verbs}, spec ->

      verbs
      |> Enum.reduce(spec, fn verb, spec ->

        apply(__MODULE__, :spec_run_action, [verb, spec])

      end)

    end)

    # extract the asts in pipelines' verbs order
    pipelines
    |> Enum.flat_map(fn {_pipeline, verbs} ->
      verbs |> Enum.map(fn verb -> spec |> spec_asts_verb_get(verb) end)
    end)
    |> List.flatten
    |> Enum.reject(&is_nil/1)

  end

  @doc ~S"""
  Registering or Including Function Definitions

  ## Options

    * `:include`the names of the functions to include from the module.

    * `:register` the names of the function to save in the module.

    * `:module` the name of the module to include the registered functions from.

    * `:filter` a function to filter the `:include` function definitions.

    * `:mapper` a function to transform the `:include` function definitions.

  """

  @spec __using__(use_options) :: [Macro.t]
  defmacro __using__(opts \\[]) do

    %{
      caller_module: __CALLER__.module,
      opts: opts,
    }
    |> spec_run_pipelines

   end

end

