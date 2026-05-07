defmodule Lotte.Users.ActivationTokenModel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @token_bytes 32
  @ttl_hours 24 * 7

  schema "activation_token" do
    field :token_hash, :string
    field :expires_at, :naive_datetime
    field :consumed_at, :naive_datetime

    belongs_to :user, Lotte.Users.UserModel

    timestamps()
  end

  @doc """
  Builds a fresh token for the user. Returns `{token_string, changeset}`.
  The `token_string` is what we put in the activation link sent by email
  — it is never stored. The changeset contains the SHA-256 hash of that
  token, which is what we look up at activation time.
  """
  def build(user_id) do
    token = :crypto.strong_rand_bytes(@token_bytes) |> Base.url_encode64(padding: false)
    hash = hash_token(token)

    changeset =
      %__MODULE__{}
      |> cast(%{user_id: user_id, token_hash: hash, expires_at: expiry()}, [
        :user_id,
        :token_hash,
        :expires_at
      ])
      |> validate_required([:user_id, :token_hash, :expires_at])
      |> assoc_constraint(:user)

    {token, changeset}
  end

  def consume_changeset(token) do
    change(token, consumed_at: now())
  end

  def hash_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token) |> Base.url_encode64(padding: false)
  end

  def expired?(%__MODULE__{expires_at: expires_at}) do
    NaiveDateTime.compare(now(), expires_at) == :gt
  end

  def consumed?(%__MODULE__{consumed_at: nil}), do: false
  def consumed?(%__MODULE__{}), do: true

  defp expiry do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(@ttl_hours * 3600, :second)
    |> NaiveDateTime.truncate(:second)
  end

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
end
