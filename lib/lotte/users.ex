defmodule Lotte.Users do
  @moduledoc """
  User identity context. Owns User + the identity records that
  authenticate them (EmailIdentity for the unactivated email-only state,
  EmailPasswordIdentity for the activated state) and ActivationToken for
  the email link a user clicks to activate.

  See `lib/lotte/users/*_model.ex` for the schemas.
  """
  import Ecto.Query

  alias Ecto.Multi
  alias Lotte.Mailer
  alias Lotte.Repo

  alias Lotte.Users.{
    ActivationEmail,
    ActivationTokenModel,
    EmailIdentityModel,
    EmailPasswordIdentityModel,
    UserModel
  }

  @doc """
  Registers a new user from an email address. Creates the User and the
  EmailIdentity satellite, plus an ActivationToken for the email link.

  Returns `{:ok, %{user: user, token: token_string}}` on success — the
  `token_string` is the unhashed token to embed in the activation URL.

  Returns `{:error, changeset}` on validation failure (invalid format,
  email already taken, etc).
  """
  def register_with_email(email) do
    Multi.new()
    |> Multi.insert(:user, UserModel.registration_changeset(%UserModel{}, %{email: email}))
    |> Multi.insert(:email_identity, fn %{user: user} ->
      EmailIdentityModel.changeset(%EmailIdentityModel{}, %{user_id: user.id})
    end)
    |> Multi.run(:token, fn _repo, %{user: user} ->
      {token, changeset} = ActivationTokenModel.build(user.id)

      case Repo.insert(changeset) do
        {:ok, _record} -> {:ok, token}
        {:error, changeset} -> {:error, changeset}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user, token: token}} -> {:ok, %{user: user, token: token}}
      {:error, _step, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Activates a user via a clicked email link.

  Looks up the (unconsumed, unexpired) token, then atomically:
  - creates the EmailPasswordIdentity from the form attrs
  - marks the token consumed
  - sets `confirmed_at` on the user
  """
  def activate(token, attrs) do
    case fetch_active_token(token) do
      {:ok, token_record} ->
        attrs = Map.put(attrs, "user_id", token_record.user_id)

        Multi.new()
        |> Multi.insert(
          :identity,
          EmailPasswordIdentityModel.activation_changeset(%EmailPasswordIdentityModel{}, attrs)
        )
        |> Multi.update(:token, ActivationTokenModel.consume_changeset(token_record))
        |> Multi.update(:user, fn %{identity: identity} ->
          user = Repo.get!(UserModel, identity.user_id)
          UserModel.confirm_changeset(user)
        end)
        |> Repo.transaction()
        |> case do
          {:ok, %{user: user}} -> {:ok, user}
          {:error, _step, changeset, _} -> {:error, changeset}
        end

      :error ->
        {:error, :invalid_token}
    end
  end

  @doc """
  Issues a fresh activation token for a user, invalidating any prior one.
  Returns `{:ok, token_string}` (the unhashed token to embed in the link).
  """
  def reissue_activation_token(%UserModel{id: user_id}) do
    {token, changeset} = ActivationTokenModel.build(user_id)

    Multi.new()
    |> Multi.delete_all(
      :delete_old,
      from(t in ActivationTokenModel, where: t.user_id == ^user_id)
    )
    |> Multi.insert(:token, changeset)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> {:ok, token}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Authenticates an email + password pair for an activated user.
  Returns the user on success, nil otherwise. Constant-time on failure
  (does a dummy bcrypt verify) to mitigate user-enumeration via timing.
  """
  def authenticate_with_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    identity = if user, do: get_password_identity(user), else: nil

    if identity && EmailPasswordIdentityModel.valid_password?(identity, password) do
      user
    else
      EmailPasswordIdentityModel.valid_password?(nil, password)
      nil
    end
  end

  def get_user(id), do: Repo.get(UserModel, id)
  def get_user!(id), do: Repo.get!(UserModel, id)

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(UserModel, email: String.downcase(email))
  end

  def activated?(%UserModel{} = user), do: not is_nil(user.confirmed_at)

  @doc """
  Sends the activation email. Caller supplies the URL builder
  (e.g. `&LotteWeb.Router.Helpers.activation_url(conn, :show, &1)`)
  so the context stays free of web concerns.
  """
  def deliver_activation_email(%UserModel{email: email}, token, url_for_token)
      when is_binary(token) and is_function(url_for_token, 1) do
    email
    |> ActivationEmail.build(url_for_token.(token))
    |> Mailer.deliver()
  end

  defp get_password_identity(%UserModel{id: user_id}) do
    Repo.get_by(EmailPasswordIdentityModel, user_id: user_id)
  end

  defp fetch_active_token(token) when is_binary(token) do
    hash = ActivationTokenModel.hash_token(token)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    query =
      from t in ActivationTokenModel,
        where: t.token_hash == ^hash and is_nil(t.consumed_at) and t.expires_at > ^now

    case Repo.one(query) do
      nil -> :error
      token -> {:ok, token}
    end
  end
end
