defmodule DLB.Server.Amnesia.Test do
  alias DLB.Server.Amnesia
  use ExUnit.Case

  test "add" do
    a = Amnesia.new(10) |> Amnesia.add(self())
    :timer.sleep(5)
    a = Amnesia.add(a, self())
    assert a.blocks |> Enum.count() == 2
    :timer.sleep(6)
    assert a.blocks |> Enum.count() == 2
    a = Amnesia.add(a, self())
    assert a.blocks |> Enum.count() == 2

    assert Amnesia.select_worker(a, 1) == {a, [self()]}
  end
end
