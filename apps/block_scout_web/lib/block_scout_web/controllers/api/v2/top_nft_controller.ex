# SPDX-License-Identifier: LicenseRef-Blockscout
defmodule BlockScoutWeb.API.V2.TopNftController do
  @moduledoc """
  GET /api/v2/nfts — top NFT collections (ERC-721 + ERC-1155).

  Returns, per collection, the number of token transfers in the last 24 hours
  and last 2 days, sorted by one of those counts. Mirrors the legacy
  "Non-Fungible Token Tracker" page.

  Query params: `q` (name/symbol filter), `sort` (transfers_24h | transfers_2d),
  `order` (asc | desc), `page_number`, `page_size`.
  """
  use BlockScoutWeb, :controller

  alias BlockScoutWeb.TopNftCache
  alias Explorer.Chain.TopNft

  action_fallback(BlockScoutWeb.API.V2.FallbackController)

  @default_page_size 50
  @max_page_size 100

  def top_nfts(conn, params) do
    page_number = parse_int(params["page_number"], 1, 1)
    page_size = parse_int(params["page_size"], @default_page_size, 1, @max_page_size)
    sort = params["sort"] || "transfers_24h"
    order = params["order"] || "desc"

    cache_key = {params["q"], page_number, page_size, sort, order}

    rows =
      case TopNftCache.get(cache_key) do
        {:ok, cached} -> cached
        :miss -> TopNftCache.put(cache_key, TopNft.list(params["q"], page_number, page_size, sort, order))
      end

    {items, has_next?} =
      case Enum.split(rows, page_size) do
        {page, []} -> {page, false}
        {page, _extra} -> {page, true}
      end

    next_page_params =
      if has_next? do
        %{"page_number" => page_number + 1, "page_size" => page_size, "sort" => sort, "order" => order}
      end

    json(conn, %{"items" => items, "next_page_params" => next_page_params})
  end

  defp parse_int(value, default, min_value, max_value \\ nil) do
    parsed = to_int(value, default)
    parsed = Kernel.max(parsed, min_value)
    if max_value, do: Kernel.min(parsed, max_value), else: parsed
  end

  defp to_int(value, _default) when is_integer(value), do: value

  defp to_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp to_int(_value, default), do: default
end
