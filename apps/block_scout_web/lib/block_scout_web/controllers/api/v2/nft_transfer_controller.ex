# SPDX-License-Identifier: LicenseRef-Blockscout
defmodule BlockScoutWeb.API.V2.NftTransferController do
  @moduledoc """
  GET /api/v2/nfts/transfers — all NFT (ERC-721 + ERC-1155) token transfers.
  """
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain,
    only: [
      split_list_by_page: 1,
      paging_options: 1,
      token_transfers_next_page_params: 3,
      fetch_scam_token_toggle: 2
    ]

  import BlockScoutWeb.PagingHelper,
    only: [delete_parameters_from_next_page_params: 1]

  import Explorer.MicroserviceInterfaces.BENS, only: [maybe_preload_ens_for_token_transfers: 1]
  import Explorer.MicroserviceInterfaces.Metadata, only: [maybe_preload_metadata: 1]

  alias BlockScoutWeb.API.V2.TokenTransferView
  alias Explorer.Chain
  alias Explorer.Chain.{TokenTransfer, Transaction}
  alias Explorer.Chain.Token.Instance

  action_fallback(BlockScoutWeb.API.V2.FallbackController)

  @api_true [api?: true]
  @nft_types ["ERC-721"]

  def nft_transfers(conn, params) do
    render_token_transfers(conn, params, &TokenTransfer.fetch/1)
  end

  defp render_token_transfers(conn, params, fetch_fun) do
    paging_options = paging_options(params)

    options =
      paging_options
      |> Keyword.merge(token_type: @nft_types)
      |> Keyword.merge(@api_true)
      |> fetch_scam_token_toggle(conn)

    {token_transfers, next_page} =
      options
      |> fetch_fun.()
      |> Chain.flat_1155_batch_token_transfers()
      |> Chain.paginate_1155_batch_token_transfers(paging_options)
      |> split_list_by_page()

    transactions = token_transfers |> Enum.map(& &1.transaction) |> Enum.uniq()
    decoded_transactions = Transaction.decode_transactions(transactions, true, @api_true)

    decoded_transactions_map =
      transactions
      |> Enum.zip(decoded_transactions)
      |> Enum.into(%{}, fn {%{hash: hash}, decoded_input} -> {hash, decoded_input} end)

    next_page_params =
      next_page
      |> token_transfers_next_page_params(token_transfers, params)
      |> delete_parameters_from_next_page_params()

    conn
    |> put_status(200)
    |> put_view(TokenTransferView)
    |> render(:token_transfers, %{
      token_transfers:
        token_transfers
        |> Instance.preload_nft(@api_true)
        |> maybe_preload_ens_for_token_transfers()
        |> maybe_preload_metadata(),
      decoded_transactions_map: decoded_transactions_map,
      next_page_params: next_page_params
    })
  end
end
