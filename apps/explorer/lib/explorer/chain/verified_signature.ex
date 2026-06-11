# SPDX-License-Identifier: LicenseRef-Blockscout
defmodule Explorer.Chain.VerifiedSignature do
  @moduledoc """
  Represents a verified message signature published on-chain explorer.

  Fields:
    * `:id`           - auto-increment primary key
    * `:address_hash` - signer's address (string)
    * `:message`      - original message that was signed
    * `:hash`         - signature hash (unique per message+hash pair)
    * `:inserted_at`  - publication timestamp
  """

  use Explorer.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Explorer.Repo

  @required_attrs ~w(address_hash message hash)a

  @type t :: %__MODULE__{
          address_hash: String.t(),
          message: String.t(),
          hash: String.t()
        }

  schema "verified_signatures" do
    field(:message, :string)
    field(:hash, :string)
    field(:address_hash, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(%__MODULE__{} = verified_signature, attrs \\ %{}) do
    verified_signature
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
  end

  @doc "Returns paginated list of verified signatures, optionally filtered by ID or address."
  def list(options \\ []) do
    page_size = Keyword.get(options, :page_size, 50)
    page_number = Keyword.get(options, :page_number, 1)
    search = Keyword.get(options, :search, nil)

    __MODULE__
    |> apply_search(search)
    |> order_by(desc: :id)
    |> offset(^(page_size * (page_number - 1)))
    |> limit(^(page_size + 1))
    |> Repo.replica().all()
  end

  @doc "Counts verified signatures, optionally filtered."
  def count(options \\ []) do
    search = Keyword.get(options, :search, nil)

    __MODULE__
    |> apply_search(search)
    |> Repo.aggregate(:count, :id)
  end

  @doc "Fetches a single verified signature by ID."
  def get(id) do
    __MODULE__
    |> where(id: ^id)
    |> Repo.one()
  end

  @doc """
  Inserts a new verified signature.
  Returns {:ok, record}, {:duplicate, existing}, or {:error, changeset}.
  """
  def insert(%{"address_hash" => _, "message" => _, "hash" => hash} = attrs) do
    case Repo.one(from(s in __MODULE__, where: s.hash == ^hash)) do
      nil ->
        attrs
        |> (&changeset(%__MODULE__{}, &1)).()
        |> Repo.insert()

      existing ->
        {:duplicate, existing}
    end
  end

  defp apply_search(query, nil), do: query
  defp apply_search(query, ""), do: query

  defp apply_search(query, search) do
    case Integer.parse(search) do
      {id, ""} -> where(query, [s], s.id == ^id)
      _ -> where(query, [s], ilike(s.address_hash, ^"%#{search}%"))
    end
  end
end
