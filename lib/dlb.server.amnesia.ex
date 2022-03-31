defmodule DLB.Server.Amnesia do
  defmodule Block do
    defstruct worker: nil, expired_at: 0, is_expired: false

    @type t :: %__MODULE__{
            worker: pid,
            expired_at: integer,
            is_expired: boolean
          }

    def new(worker, ttl_in_ms) when is_pid(worker) and is_integer(ttl_in_ms) do
      %__MODULE__{
        worker: worker,
        expired_at: System.os_time(:millisecond) + ttl_in_ms,
        is_expired: false
      }
    end
  end

  defstruct blocks: [], ttl_in_ms: 0

  def new(ttl_in_ms) when is_integer(ttl_in_ms) do
    %__MODULE__{
      blocks: [],
      ttl_in_ms: ttl_in_ms
    }
  end

  def add(amnesia, worker) when is_pid(worker) and is_struct(amnesia, __MODULE__) do
    remove_expired_blocks(%{
      amnesia
      | blocks: [DLB.Server.Amnesia.Block.new(worker, amnesia.ttl_in_ms) | amnesia.blocks]
    })
  end

  def select_worker(amnesia, n) when is_struct(amnesia, __MODULE__) and is_integer(n) do
    amnesia = remove_expired_blocks(amnesia)
    {amnesia, Enum.take_random(amnesia.blocks, n) |> Enum.map(fn b -> b.worker end)}
  end

  defp remove_expired_blocks_recursive(_, ttl_in_ms, acc_blocks, [])
       when is_integer(ttl_in_ms) and is_list(acc_blocks) do
    %__MODULE__{blocks: Enum.reverse(acc_blocks), ttl_in_ms: ttl_in_ms}
  end

  defp remove_expired_blocks_recursive(now, ttl_in_ms, acc_blocks, [h | t])
       when is_integer(ttl_in_ms) and is_list(acc_blocks) and
              is_struct(h, __MODULE__.Block) do
    if h.is_expired or h.expired_at < now do
      remove_expired_blocks_recursive(now, ttl_in_ms, acc_blocks, t)
    else
      remove_expired_blocks_recursive(now, ttl_in_ms, [h | acc_blocks], t)
    end
  end

  defp remove_expired_blocks(amnesia) when is_struct(amnesia, __MODULE__) do
    remove_expired_blocks_recursive(
      System.os_time(:millisecond),
      amnesia.ttl_in_ms,
      [],
      amnesia.blocks
    )
  end
end
