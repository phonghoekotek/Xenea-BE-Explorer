# SPDX-License-Identifier: LicenseRef-Blockscout
defmodule Explorer.Chain.TopNft do
  @moduledoc """
  Aggregated "Top NFTs" listing used by GET /api/v2/nfts.

  For every NFT collection (ERC-721 / ERC-1155) it counts the number of token
  transfers in the last 24 hours and the last 2 days, sorted by one of those
  counts. Ported from the legacy explorer's `Chain.list_top_nfts/4`.
  """

  alias Explorer.Repo

  @nft_types ["ERC-721", "ERC-1155"]

  @allowed_sort %{"transfers_24h" => "transfers_24h", "transfers_2d" => "transfers_2d"}
  @allowed_order %{"asc" => "ASC", "desc" => "DESC"}

  @doc """
  Returns up to `page_size + 1` rows (the extra row signals a next page).

  Each row is a map:
      %{address_hash, name, symbol, type, transfers_24h, transfers_2d}

  * `filter`      - optional name/symbol substring filter (may be nil)
  * `page_number` - 1-based page number
  * `page_size`   - rows per page
  * `sort`        - "transfers_24h" | "transfers_2d"
  * `order`       - "asc" | "desc"
  """
  def list(filter, page_number, page_size, sort, order) do
    order_col = Map.get(@allowed_sort, sort, "transfers_24h")
    order_dir = Map.get(@allowed_order, order, "DESC")

    limit = page_size + 1
    offset = page_size * (page_number - 1)

    {filter_clause, params} =
      case normalize_filter(filter) do
        nil -> {"", [limit, offset]}
        like -> {"AND (t.name ILIKE $3 OR t.symbol ILIKE $3)", [limit, offset, like]}
      end

    # Use block_number range (indexed) instead of joining blocks for timestamp.
    # Find the min block_number for 24h and 2d windows — fast index scan on blocks(timestamp).
    # Then filter token_transfers by block_number — uses token_transfers_block_number_index.
    # This avoids a full table scan of token_transfers.
    query = """
      WITH time_bounds AS (
        SELECT
          COALESCE(MIN(number) FILTER (WHERE timestamp >= NOW() - INTERVAL '24 HOURS'), 0) AS min_block_24h,
          COALESCE(MIN(number) FILTER (WHERE timestamp >= NOW() - INTERVAL '2 DAYS'),   0) AS min_block_2d,
          MAX(number) AS max_block
        FROM blocks
        WHERE consensus = true
      ),
      recent_transfers AS (
        SELECT
          t.name,
          t.symbol,
          t.type,
          tt.token_contract_address_hash AS address_hash,
          tt.block_number
        FROM tokens t
        INNER JOIN token_transfers tt
          ON t.contract_address_hash = tt.token_contract_address_hash,
          time_bounds
        WHERE t.type = 'ERC-721'
          AND tt.block_number >= time_bounds.min_block_2d
          AND tt.block_number <= time_bounds.max_block
        #{filter_clause}
      )
      SELECT
        name,
        symbol,
        type,
        CONCAT('0x', encode(address_hash, 'hex')) AS address_hash,
        COUNT(*) FILTER (WHERE block_number >= (SELECT min_block_24h FROM time_bounds)) AS transfers_24h,
        COUNT(*) AS transfers_2d
      FROM recent_transfers
      GROUP BY name, symbol, type, address_hash
      ORDER BY #{order_col} #{order_dir}
      LIMIT $1 OFFSET $2
    """

    %Postgrex.Result{rows: rows} = Repo.replica().query!(query, params)

    Enum.map(rows, fn [name, symbol, type, address_hash, transfers_24h, transfers_2d] ->
      %{
        name: name,
        symbol: symbol,
        type: type,
        address_hash: address_hash,
        transfers_24h: transfers_24h,
        transfers_2d: transfers_2d
      }
    end)
  end

  @doc "Exposes the NFT token types this listing considers."
  def nft_types, do: @nft_types

  defp normalize_filter(nil), do: nil
  defp normalize_filter(""), do: nil

  defp normalize_filter(filter) when is_binary(filter) do
    trimmed = String.trim(filter)
    if trimmed == "", do: nil, else: "%#{trimmed}%"
  end

  defp normalize_filter(_), do: nil
end
