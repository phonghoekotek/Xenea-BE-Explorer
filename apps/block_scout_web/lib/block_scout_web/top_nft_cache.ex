# SPDX-License-Identifier: LicenseRef-Blockscout
defmodule BlockScoutWeb.TopNftCache do
  @moduledoc """
  GenServer that owns the :top_nft_cache ETS table.
  Survives request lifecycle — ETS table persists as long as this process is alive.
  """
  use GenServer

  @table :top_nft_cache
  @ttl_ms 5 * 60 * 1_000

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end

  def get(key) do
    now = :os.system_time(:millisecond)
    case :ets.lookup(@table, key) do
      [{^key, value, expires_at}] when is_integer(expires_at) and expires_at > now -> {:ok, value}
      _ -> :miss
    end
  end

  def put(key, value) do
    expires_at = :os.system_time(:millisecond) + @ttl_ms
    :ets.insert(@table, {key, value, expires_at})
    value
  end
end
