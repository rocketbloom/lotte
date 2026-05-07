defmodule Lotte.Users.EmailPasswordIdentityModel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @min_password_length 8
  @max_password_length 72

  @derive {Inspect, except: [:password, :password_confirmation, :hashed_password]}
  schema "email_password_identity" do
    field :hashed_password, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :terms_accepted_at, :naive_datetime
    field :privacy_accepted_at, :naive_datetime

    field :accept_terms, :boolean, virtual: true
    field :accept_privacy, :boolean, virtual: true

    belongs_to :user, Lotte.Users.UserModel

    timestamps()
  end

  def activation_changeset(identity, attrs) do
    identity
    |> cast(attrs, [
      :user_id,
      :password,
      :password_confirmation,
      :accept_terms,
      :accept_privacy
    ])
    |> validate_required([:user_id, :password, :password_confirmation])
    |> validate_length(:password, min: @min_password_length, max: @max_password_length)
    |> validate_confirmation(:password,
      message: "does not match password",
      required: true
    )
    |> validate_acceptance(:accept_terms, message: "you must accept the terms")
    |> validate_acceptance(:accept_privacy, message: "you must accept the privacy policy")
    |> put_acceptance_timestamps()
    |> hash_password()
    |> unique_constraint(:user_id)
    |> assoc_constraint(:user)
  end

  defp put_acceptance_timestamps(changeset) do
    if changeset.valid? do
      changeset
      |> put_change(:terms_accepted_at, now())
      |> put_change(:privacy_accepted_at, now())
    else
      changeset
    end
  end

  defp hash_password(changeset) do
    if password = get_change(changeset, :password) do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
      |> delete_change(:password_confirmation)
    else
      changeset
    end
  end

  def valid_password?(%__MODULE__{hashed_password: hash}, password)
      when is_binary(hash) and is_binary(password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hash)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
end
