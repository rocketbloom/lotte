defmodule Lotte.Users.UserModel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @email_format ~r/^[^\s]+@[^\s]+$/
  @email_max_length 160
  @roles ~w(owner member)

  schema "user" do
    field :email, :string
    field :role, :string
    field :confirmed_at, :naive_datetime

    belongs_to :tenant, Lotte.Tenants.TenantModel, type: :binary_id

    has_one :email_identity, Lotte.Users.EmailIdentityModel, foreign_key: :user_id
    has_one :email_password_identity, Lotte.Users.EmailPasswordIdentityModel,
      foreign_key: :user_id
    has_one :activation_token, Lotte.Users.ActivationTokenModel, foreign_key: :user_id

    timestamps()
  end

  def email_format, do: @email_format
  def email_max_length, do: @email_max_length

  def valid_email?(email) when is_binary(email) do
    String.length(email) <= @email_max_length and String.match?(email, @email_format)
  end

  def valid_email?(_), do: false

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_email()
  end

  def assign_tenant_changeset(user, tenant_id, role) when role in @roles do
    user
    |> change(tenant_id: tenant_id, role: role)
  end

  def confirm_changeset(user) do
    change(user, confirmed_at: now())
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, @email_format, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: @email_max_length)
    |> update_change(:email, &String.downcase/1)
    |> unsafe_validate_unique(:email, Lotte.Repo)
    |> unique_constraint(:email)
  end

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
end
