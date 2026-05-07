defmodule Lotte.Users.EmailIdentityModel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "email_identity" do
    field :validation_data, :map
    field :validated_at, :naive_datetime

    belongs_to :user, Lotte.Users.UserModel

    timestamps()
  end

  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:user_id, :validation_data, :validated_at])
    |> validate_required([:user_id])
    |> assoc_constraint(:user)
    |> unique_constraint(:user_id)
  end
end
