# SPDX-License-Identifier: LicenseRef-Blockscout

defmodule BlockScoutWeb.API.V2.DocsController do
  use BlockScoutWeb, :controller

  def index(conn, _params) do
    docs = %{
      "title" => "Xenia API Documentation",
      "description" => "Comprehensive REST API for Xenia blockchain explorer",
      "version" => "2.0.0",
      "baseUrl" => "#{get_base_url(conn)}/api/v2",
      "xenia_endpoints" => get_xenia_endpoints(),
      "endpoints" => get_endpoints(),
      "features" => get_features(),
      "authentication" => get_authentication(),
      "rateLimit" => get_rate_limit(),
      "commonParams" => get_common_params(),
      "responseFormat" => get_response_format()
    }

    json(conn, docs)
  end

  defp get_base_url(conn) do
    "#{conn.adapter |> elem(0) |> to_string() |> String.slice(0..-3)}://#{conn.host}"
  end

  defp get_xenia_endpoints do
    %{
      "nft_tracking" => %{
        "description" => "Xenia NFT Tracking - Track Non-Fungible Tokens across the network",
        "endpoints" => [
          %{
            "method" => "GET",
            "path" => "/nfts",
            "title" => "Top NFT Collections",
            "description" => "Get top NFT collections (ERC-721 + ERC-1155) ranked by transfer activity in the last 24h or 2 days",
            "queryParams" => [
              %{
                "name" => "sort",
                "type" => "string",
                "required" => false,
                "enum" => ["transfers_24h", "transfers_2d"],
                "default" => "transfers_24h",
                "description" => "Sort by transfer count in the last 24 hours or 2 days"
              },
              %{
                "name" => "order",
                "type" => "string",
                "required" => false,
                "enum" => ["asc", "desc"],
                "default" => "desc",
                "description" => "Sort direction (ascending or descending)"
              },
              %{
                "name" => "q",
                "type" => "string",
                "required" => false,
                "description" => "Search filter by collection name or symbol"
              },
              %{
                "name" => "page_number",
                "type" => "integer",
                "required" => false,
                "default" => 1,
                "description" => "Page number for pagination"
              },
              %{
                "name" => "page_size",
                "type" => "integer",
                "required" => false,
                "default" => 50,
                "maximum" => 100,
                "description" => "Number of items per page (max 100)"
              }
            ],
            "response" => %{
              "status" => 200,
              "schema" => %{
                "items" => [
                  %{
                    "address_hash" => "0x..." <> " (string) - Contract address",
                    "name" => "Collection Name",
                    "symbol" => "NFT",
                    "type" => "ERC-721",
                    "transfers_24h" => 500,
                    "transfers_2d" => 1200
                  }
                ],
                "next_page_params" => %{
                  "page_number" => 2,
                  "page_size" => 50,
                  "sort" => "transfers_24h",
                  "order" => "desc"
                }
              }
            }
          },
          %{
            "method" => "GET",
            "path" => "/nfts/transfers",
            "title" => "NFT Transfers",
            "description" => "Get all NFT (ERC-721 + ERC-1155) token transfer transactions across the network",
            "queryParams" => [
              %{
                "name" => "page_number",
                "type" => "integer",
                "required" => false,
                "default" => 1,
                "description" => "Page number for pagination"
              },
              %{
                "name" => "page_size",
                "type" => "integer",
                "required" => false,
                "default" => 50,
                "maximum" => 100,
                "description" => "Number of items per page (max 100)"
              }
            ],
            "response" => %{
              "status" => 200,
              "description" => "List of NFT transfer transactions with pagination"
            }
          },
          %{
            "method" => "GET",
            "path" => "/nfts/mints",
            "title" => "Latest NFT Mints",
            "description" => "Get recent NFT mint transactions (transfers from the zero address)",
            "queryParams" => [
              %{
                "name" => "page_number",
                "type" => "integer",
                "required" => false,
                "default" => 1,
                "description" => "Page number for pagination"
              },
              %{
                "name" => "page_size",
                "type" => "integer",
                "required" => false,
                "default" => 50,
                "maximum" => 100,
                "description" => "Number of items per page (max 100)"
              }
            ],
            "response" => %{
              "status" => 200,
              "description" => "List of recent NFT mint transactions with pagination"
            }
          }
        ]
      },
      "verified_signatures" => %{
        "description" => "Xenia Verified Signatures - Publish and verify signed messages on the blockchain",
        "endpoints" => [
          %{
            "method" => "GET",
            "path" => "/verified-signatures",
            "title" => "List Verified Signatures",
            "description" => "Get paginated list of published verified signatures with optional search filter",
            "queryParams" => [
              %{
                "name" => "q",
                "type" => "string",
                "required" => false,
                "description" => "Search filter for signatures (searches address_hash and message)"
              },
              %{
                "name" => "search",
                "type" => "string",
                "required" => false,
                "description" => "Alternative search parameter (same as 'q')"
              },
              %{
                "name" => "page_number",
                "type" => "integer",
                "required" => false,
                "default" => 1,
                "description" => "Page number for pagination"
              },
              %{
                "name" => "page_size",
                "type" => "integer",
                "required" => false,
                "default" => 50,
                "maximum" => 100,
                "description" => "Number of items per page (max 100)"
              }
            ],
            "response" => %{
              "status" => 200,
              "schema" => %{
                "items" => [
                  %{
                    "id" => "uuid-string",
                    "address_hash" => "0x..." <> " (string) - Signer address",
                    "message" => "Signed message content",
                    "hash" => "0x..." <> " (string) - Message signature hash",
                    "created_at" => "2024-01-15T10:30:00Z"
                  }
                ],
                "next_page_params" => %{
                  "page_number" => 2,
                  "page_size" => 50
                },
                "total_count" => 1500
              }
            }
          },
          %{
            "method" => "POST",
            "path" => "/verified-signatures",
            "title" => "Publish Verified Signature",
            "description" => "Publish a new verified signature (signed message) to the blockchain explorer",
            "requestBody" => %{
              "required" => true,
              "contentType" => "application/json",
              "schema" => %{
                "address_hash" => "0x..." <> " (string, required) - Signer address",
                "message" => "string, required - Original signed message",
                "hash" => "0x..." <> " (string, required) - Message signature hash (v + r + s)"
              }
            },
            "response" => %{
              "status_success" => 201,
              "status_conflict" => 409,
              "status_error" => 400,
              "schema" => %{
                "id" => "uuid-string",
                "address_hash" => "0x...",
                "message" => "Signed message",
                "hash" => "0x...",
                "created_at" => "2024-01-15T10:30:00Z"
              }
            }
          },
          %{
            "method" => "GET",
            "path" => "/verified-signatures/:id",
            "title" => "Get Signature by ID",
            "description" => "Fetch a single verified signature by its unique identifier",
            "pathParams" => [
              %{
                "name" => "id",
                "type" => "string",
                "required" => true,
                "description" => "UUID of the verified signature"
              }
            ],
            "response" => %{
              "status_success" => 200,
              "status_notfound" => 404,
              "schema" => %{
                "id" => "uuid-string",
                "address_hash" => "0x...",
                "message" => "Signed message",
                "hash" => "0x...",
                "created_at" => "2024-01-15T10:30:00Z"
              }
            }
          }
        ]
      }
    }
  end

  defp get_endpoints do
    %{
      "nfts" => %{
        "description" => "Non-Fungible Token (NFT) endpoints",
        "endpoints" => [
          %{
            "path" => "GET /nfts",
            "description" => "Get list of top NFT collections by transfers",
            "queryParams" => [
              %{"name" => "sort", "type" => "string", "values" => ["transfers_24h", "transfers_2d"], "default" => "transfers_24h"},
              %{"name" => "order", "type" => "string", "values" => ["asc", "desc"], "default" => "desc"},
              %{"name" => "page", "type" => "integer", "default" => 1},
              %{"name" => "page_size", "type" => "integer", "default" => 50}
            ],
            "response" => %{
              "items" => [
                %{
                  "address_hash" => "0x...",
                  "name" => "Collection Name",
                  "symbol" => "SYMBOL",
                  "type" => "ERC-721",
                  "transfers_24h" => 123,
                  "transfers_2d" => 456
                }
              ],
              "next_page_params" => %{
                "page_number" => 2,
                "page_size" => 50,
                "sort" => "transfers_24h",
                "order" => "desc"
              }
            }
          },
          %{
            "path" => "GET /nfts/transfers",
            "description" => "Get NFT transfer transactions",
            "queryParams" => [
              %{"name" => "page", "type" => "integer", "default" => 1},
              %{"name" => "page_size", "type" => "integer", "default" => 50}
            ]
          },
          %{
            "path" => "GET /nfts/mints",
            "description" => "Get recent NFT mint transactions",
            "queryParams" => [
              %{"name" => "page", "type" => "integer", "default" => 1},
              %{"name" => "page_size", "type" => "integer", "default" => 50}
            ]
          }
        ]
      },
      "tokens" => %{
        "description" => "Token and balance endpoints",
        "endpoints" => [
          %{
            "path" => "GET /tokens",
            "description" => "Get list of tokens",
            "queryParams" => [
              %{"name" => "type", "type" => "string", "values" => ["ERC-20", "ERC-721", "ERC-1155"]},
              %{"name" => "page", "type" => "integer", "default" => 1},
              %{"name" => "page_size", "type" => "integer", "default" => 50}
            ]
          },
          %{
            "path" => "GET /token-transfers",
            "description" => "Get token transfer transactions",
            "queryParams" => [
              %{"name" => "type", "type" => "string"},
              %{"name" => "page", "type" => "integer", "default" => 1},
              %{"name" => "page_size", "type" => "integer", "default" => 50}
            ]
          }
        ]
      },
      "blockchain" => %{
        "description" => "Blockchain data endpoints",
        "endpoints" => [
          %{
            "path" => "GET /accounts",
            "description" => "Get list of accounts/addresses"
          },
          %{
            "path" => "GET /blocks",
            "description" => "Get list of blocks"
          },
          %{
            "path" => "GET /transactions",
            "description" => "Get list of transactions"
          }
        ]
      }
    }
  end

  defp get_features do
    [
      "REST API v2 endpoints",
      "GraphQL API support",
      "WebSocket real-time updates",
      "NFT tracking and analytics",
      "Token transfer history",
      "Smart contract verification",
      "Address tagging and labeling",
      "Transaction decoding",
      "ERC-20, ERC-721, ERC-1155 support"
    ]
  end

  defp get_authentication do
    %{
      "description" => "The Xenia API is public and does not require authentication",
      "note" => "Rate limiting may apply based on IP address"
    }
  end

  defp get_rate_limit do
    %{
      "description" => "API requests are rate limited to prevent abuse",
      "default" => "Apply per IP address",
      "note" => "Contact Xenia for higher rate limits"
    }
  end

  defp get_common_params do
    %{
      "pagination" => %{
        "page" => %{"type" => "integer", "description" => "Page number (starts at 1)", "default" => 1},
        "page_size" => %{"type" => "integer", "description" => "Items per page", "default" => 50, "max" => 250}
      },
      "sorting" => %{
        "sort" => %{"type" => "string", "description" => "Sort field"},
        "order" => %{"type" => "string", "description" => "Sort order", "values" => ["asc", "desc"], "default" => "desc"}
      }
    }
  end

  defp get_response_format do
    %{
      "success" => %{
        "statusCode" => 200,
        "format" => %{
          "items" => ["array of results"],
          "next_page_params" => "pagination parameters for next page or null if last page"
        }
      },
      "error" => %{
        "statusCode" => 400,
        "format" => %{
          "errors" => [
            %{
              "title" => "Error title",
              "detail" => "Error description"
            }
          ]
        }
      }
    }
  end
end
