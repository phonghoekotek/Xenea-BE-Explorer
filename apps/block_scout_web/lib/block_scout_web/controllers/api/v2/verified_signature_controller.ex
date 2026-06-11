# SPDX-License-Identifier: LicenseRef-Blockscout
defmodule BlockScoutWeb.API.V2.VerifiedSignatureController do
  @moduledoc """
  V2 API endpoints for verified message signatures (Xenia feature).

    * GET  /api/v2/verified-signatures        - paginated list, optional ?search=
    * POST /api/v2/verified-signatures        - publish a new verified signature
    * GET  /api/v2/verified-signatures/:id    - fetch a single signature by ID
  """
  use BlockScoutWeb, :controller

  alias Explorer.Chain.VerifiedSignature

  action_fallback(BlockScoutWeb.API.V2.FallbackController)

  @default_page_size 50
  @max_page_size 100

  def index(conn, params) do
    page_number = parse_int(params["page_number"], 1, 1)
    page_size = parse_int(params["page_size"], @default_page_size, 1, @max_page_size)
    search = params["q"] || params["search"]

    options = [page_number: page_number, page_size: page_size, search: search]

    rows = VerifiedSignature.list(options)
    count = VerifiedSignature.count(options)

    {items, has_next?} =
      case Enum.split(rows, page_size) do
        {page, []} -> {page, false}
        {page, _} -> {page, true}
      end

    next_page_params =
      if has_next? do
        %{"page_number" => page_number + 1, "page_size" => page_size}
        |> maybe_put("search", search)
      end

    json(conn, %{
      "items" => Enum.map(items, &prepare/1),
      "next_page_params" => next_page_params,
      "total_count" => count
    })
  end

  def show(conn, %{"id" => id}) do
    case VerifiedSignature.get(id) do
      nil -> {:error, :not_found}
      sig -> json(conn, prepare(sig))
    end
  end

  def create(conn, %{"address_hash" => _, "message" => _, "hash" => _} = params) do
    case VerifiedSignature.insert(params) do
      {:ok, sig} ->
        conn
        |> put_status(201)
        |> json(prepare(sig))

      {:duplicate, existing} ->
        conn
        |> put_status(409)
        |> json(%{"error" => "duplicate", "id" => existing.id})

      {:error, _changeset} ->
        conn
        |> put_status(400)
        |> json(%{"error" => "invalid_params"})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{"error" => "address_hash, message, and hash are required"})
  end

  defp prepare(sig) do
    %{
      "id" => sig.id,
      "address_hash" => sig.address_hash,
      "message" => sig.message,
      "hash" => sig.hash,
      "inserted_at" => sig.inserted_at
    }
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp parse_int(value, default, min_val, max_val \\ nil) do
    parsed =
      case value do
        nil -> default
        v when is_integer(v) -> v
        v -> elem(Integer.parse(to_string(v)), 0)
      end

    parsed = max(parsed, min_val)
    if max_val, do: min(parsed, max_val), else: parsed
  end
end
