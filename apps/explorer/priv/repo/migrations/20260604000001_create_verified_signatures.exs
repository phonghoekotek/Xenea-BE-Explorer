defmodule Explorer.Repo.Migrations.CreateVerifiedSignatures do
  use Ecto.Migration

  def change do
    create table(:verified_signatures) do
      add(:message, :text, null: false)
      add(:hash, :text, null: false)
      add(:address_hash, :string, null: false)

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(unique_index(:verified_signatures, [:hash]))
  end
end
