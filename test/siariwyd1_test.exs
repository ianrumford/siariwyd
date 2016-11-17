defmodule SiariwydDonorA1Test do

  use Siariwyd, register: [:handle_call, :handle_cast, :handle_info]

  def handle_call({:donor_a_call_1, value}, _fromref, state) do

    {:reply, {:donor_a_call_1, value}, state}

  end

  def handle_call({:donor_a_call_2, value}, _fromref, state) when is_atom(value) do

    {:reply, {:donor_a_call_2, value}, state}

  end

  def handle_call({:donor_a_call_3, value}, _fromref, state) when is_binary(value) and is_map(state) do

    {:reply, {:donor_a_call_3, value}, state}

  end

  def handle_cast({:donor_a_cast_1, _value}, state) do

    {:noreply, state}

  end

  def handle_cast({:donor_a_cast_2, value}, _state) when is_atom(value) do

    {:noreply, value}

  end

  def handle_info({:donor_a_info_1, value}, _state) do

    {:noreply, value}

  end

end

defmodule SiariwydRecipientP1Test do

  use Siariwyd, module: SiariwydDonorA1Test, include: :handle_call

end

defmodule SiariwydRecipientQ1Test do

  # use a filter
  use Siariwyd,
    module: SiariwydDonorA1Test,
    include: [:handle_call, :handle_cast, :handle_info],
    filter: fn %{args: args} = spec ->

    case args |> List.first do

      {:donor_a_call_3, _} -> true
      {:donor_a_cast_2, _} -> true
      {:donor_a_info_1, _} -> true

      _ -> false

    end

  end

end

defmodule SiariwydRecipientR1Test do

  # use a filter and mapper
  use Siariwyd,
    module: SiariwydDonorA1Test,
    include: [:handle_call, :handle_cast, :handle_info],
    filter: fn %{args: args} = spec ->

    case args |> List.first do
      {:donor_a_call_3, _} -> true
        _ -> false
    end

  end,
  mapper: fn %{args: args} = spec ->

    # only donor_a_call_3 will get through

    # change :donor_a_call_3 to repond to :donor_a_call_3_mapped
    # (but is will still reply with donor_a_call_3)
    args = args
    |> Macro.prewalk(fn snippet ->

      case snippet do

        {:donor_a_call_3, value} -> {:donor_a_call_3_mapped, value}

        # passthru
        x -> x

      end
    end)

    # using the new args, rebuild the complete function and return its ast
    spec
    |> Map.put(:args, args)
    |> Siariwyd.reconstruct_function

  end
end

defmodule SiariwydRecipientS1Test do

  # use a filter and mapper but no includes or registers - defaults to include
  use Siariwyd, module: SiariwydDonorA1Test,
  filter: fn

    %{args: args, name: :handle_call} = spec ->

    case args |> List.first do
      {:donor_a_call_3, _} -> true
        _ -> false
    end

    # discard handle_cast
    %{name: :handle_cast} -> false

    # passthru for other callbacks
    x -> x

  end,
  mapper: fn

    %{args: args, name: :handle_call} = spec ->

      # only donor_a_call_3 will get through

      # change :donor_a_call_3 to repond to :donor_a_call_3_mapped
      # (but is will still reply with donor_a_call_3)
      args = args
      |> Macro.prewalk(fn snippet ->

        case snippet do

          {:donor_a_call_3, value} -> {:donor_a_call_3_mapped, value}

          # passthru
          x -> x

        end
      end)

      # using the new args, rebuild the complete function and return its ast
      spec
      |> Map.put(:args, args)
      |> Siariwyd.reconstruct_function

    # passthru for other callbacks
    x -> x
  end

end

defmodule Siariwyd1Test do

  use ExUnit.Case

  alias SiariwydHelpersTest, as: Helpers

  test "register: SiariwydDonorA1Test" do

    assert [:handle_call, :handle_cast, :handle_info] = :attributes
    |> SiariwydDonorA1Test.__info__
    |> Keyword.get(:siariwyd_registrations)
    |> hd
    |> Map.keys

    assert [:handle_call, :handle_cast, :handle_info] =
      SiariwydDonorA1Test |> Helpers.module_registrations_keys_get

    assert [handle_call: 3, handle_cast: 2, handle_info: 1] =
      SiariwydDonorA1Test |> Helpers.module_registrations_keys_v_specs_count_get

  end

  test "include: SiariwydRecipientP1Test" do

    state = %{type: :x1}

    assert [:handle_call] = SiariwydRecipientP1Test |> Helpers.module_functions_get

    assert {:reply, {:donor_a_call_1, 42}, ^state} =
      SiariwydRecipientP1Test.handle_call({:donor_a_call_1, 42}, nil, state)

    assert {:reply, {:donor_a_call_1, :atom}, ^state} =
      SiariwydRecipientP1Test.handle_call({:donor_a_call_1, :atom}, nil, state)

    assert {:reply, {:donor_a_call_1, "string"}, ^state} =
      SiariwydRecipientP1Test.handle_call({:donor_a_call_1, "string"}, nil, state)

    assert {:reply, {:donor_a_call_2, :a2}, ^state} =
      SiariwydRecipientP1Test.handle_call({:donor_a_call_2, :a2}, nil, state)

    assert {:reply, {:donor_a_call_3, "a3"}, ^state} =
      SiariwydRecipientP1Test.handle_call({:donor_a_call_3, "a3"}, nil, state)

    # check guards enforced

    assert_raise FunctionClauseError, fn ->
      SiariwydRecipientP1Test.handle_call({:donor_a_call_2, 42}, nil, state)
    end

    assert_raise FunctionClauseError, fn ->
      SiariwydRecipientP1Test.handle_call({:donor_a_call_3, 42}, nil, state)
    end

  end

  test "include: SiariwydRecipientQ1Test" do

    state = %{type: :x1}

    assert [:handle_call, :handle_cast, :handle_info] =
      SiariwydRecipientQ1Test |> Helpers.module_functions_get

    # check no response
    assert_raise  FunctionClauseError, fn ->
      SiariwydRecipientQ1Test.handle_call({:donor_a_call_1, "string"}, nil, state)
    end

    assert_raise  FunctionClauseError, fn ->
      SiariwydRecipientQ1Test.handle_call({:donor_a_call_2, :a2}, nil, state)
    end

    assert {:reply, {:donor_a_call_3, "a3"}, ^state} =
      SiariwydRecipientQ1Test.handle_call({:donor_a_call_3, "a3"}, nil, state)

    # check guards enforced

    assert_raise FunctionClauseError, fn ->
      SiariwydRecipientQ1Test.handle_call({:donor_a_call_3, 42}, nil, state)
    end

    assert {:noreply, :a2} =
      SiariwydRecipientQ1Test.handle_cast({:donor_a_cast_2, :a2}, state)

    # check guards enforced
    assert_raise FunctionClauseError, fn ->
      SiariwydRecipientQ1Test.handle_cast({:donor_a_cast_2, 42}, state)
    end

    # check no response
    assert_raise FunctionClauseError, fn ->
      SiariwydRecipientQ1Test.handle_cast({:donor_a_cast_1, :a1}, state)
    end

    assert {:noreply, :a1} =
      SiariwydRecipientQ1Test.handle_info({:donor_a_info_1, :a1}, state)

  end

  test "include: SiariwydRecipientR1Test" do

    state = %{type: :x1}

    assert [:handle_call] =
      SiariwydRecipientR1Test |> Helpers.module_functions_get

    # donor_a_call_3 now responds to donor_a_call_3_mapped
    # but *still* replies with donor_a_call_3
    assert {:reply, {:donor_a_call_3, "a3"}, ^state} =
      SiariwydRecipientR1Test.handle_call({:donor_a_call_3_mapped, "a3"}, nil, state)

    # check guards enforced
    assert_raise FunctionClauseError, fn ->
      SiariwydRecipientR1Test.handle_call({:donor_a_call_3_mapped, 42}, nil, state)
    end

    # check no response to donor_a_call_3
    assert_raise FunctionClauseError, fn ->
      SiariwydRecipientR1Test.handle_call({:donor_a_call_3, 42}, nil, state)
    end

    # check no response
    assert_raise  FunctionClauseError, fn ->
      SiariwydRecipientR1Test.handle_call({:donor_a_call_1, "string"}, nil, state)
    end

    assert_raise  FunctionClauseError, fn ->
      SiariwydRecipientR1Test.handle_call({:donor_a_call_2, :a2}, nil, state)
    end

    # check no response

    assert_raise UndefinedFunctionError, fn ->
      SiariwydRecipientR1Test.handle_cast({:donor_a_cast_1, 42}, state)
    end

    assert_raise UndefinedFunctionError, fn ->
      SiariwydRecipientR1Test.handle_cast({:donor_a_cast_2, :a1}, state)
    end

    # check no response
    assert_raise UndefinedFunctionError, fn ->
      SiariwydRecipientR1Test.handle_cast({:donor_a_info_1, 42}, state)
    end

  end

  test "include: SiariwydRecipientS1Test" do

    state = %{type: :x1}

    assert [:handle_call, :handle_info] =
      SiariwydRecipientS1Test |> Helpers.module_functions_get

    # donor_a_call_3 now responds to donor_a_call_3_mapped
    # but *still* replies with donor_a_call_3
    assert {:reply, {:donor_a_call_3, "a3"}, ^state} =
      SiariwydRecipientS1Test.handle_call({:donor_a_call_3_mapped, "a3"}, nil, state)

    # check guards enforced
    assert_raise FunctionClauseError, fn ->
      SiariwydRecipientS1Test.handle_call({:donor_a_call_3_mapped, 42}, nil, state)
    end

    # check no response to donor_a_call_3
    assert_raise FunctionClauseError, fn ->
      SiariwydRecipientS1Test.handle_call({:donor_a_call_3, 42}, nil, state)
    end

    # check no response
    assert_raise  FunctionClauseError, fn ->
      SiariwydRecipientS1Test.handle_call({:donor_a_call_1, "string"}, nil, state)
    end

    assert_raise  FunctionClauseError, fn ->
      SiariwydRecipientS1Test.handle_call({:donor_a_call_2, :a2}, nil, state)
    end

    # check no response to handle_cast

    assert_raise UndefinedFunctionError, fn ->
      SiariwydRecipientS1Test.handle_cast({:donor_a_cast_1, 42}, state)
    end

    assert_raise UndefinedFunctionError, fn ->
      SiariwydRecipientS1Test.handle_cast({:donor_a_cast_2, :a1}, state)
    end

    assert {:noreply, :a1} =
      SiariwydRecipientS1Test.handle_info({:donor_a_info_1, :a1}, state)

  end

end

