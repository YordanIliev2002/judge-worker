defmodule JudgeWorkerTest do
  use ExUnit.Case
  doctest JudgeWorker

  test "greets the world" do
    assert JudgeWorker.hello() == :world
  end
end
