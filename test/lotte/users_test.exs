defmodule Lotte.UsersTest do
  use Lotte.DataCase, async: true

  alias Lotte.Users
  alias Lotte.Users.{UserModel, EmailIdentityModel, EmailPasswordIdentityModel}

  describe "register_with_email/1" do
    test "creates user, email identity, and activation token" do
      assert {:ok, %{user: user, token: token}} =
               Users.register_with_email("alice@example.com")

      assert user.email == "alice@example.com"
      assert is_nil(user.confirmed_at)
      assert is_binary(token)
      assert String.length(token) > 20

      assert Repo.get_by(EmailIdentityModel, user_id: user.id)
      refute Repo.get_by(EmailPasswordIdentityModel, user_id: user.id)
    end

    test "downcases the email" do
      assert {:ok, %{user: user}} = Users.register_with_email("Alice@Example.COM")
      assert user.email == "alice@example.com"
    end

    test "rejects invalid email format" do
      assert {:error, changeset} = Users.register_with_email("not-an-email")
      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "rejects duplicate email" do
      assert {:ok, _} = Users.register_with_email("dup@example.com")
      assert {:error, changeset} = Users.register_with_email("dup@example.com")
      assert "has already been taken" in errors_on(changeset).email
    end
  end

  describe "activate/2" do
    setup do
      {:ok, %{user: user, token: token}} = Users.register_with_email("activator@example.com")
      %{user: user, token: token}
    end

    test "activates with valid token + matching password + accepted terms", %{
      user: user,
      token: token
    } do
      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "supersecret",
        "accept_terms" => "true",
        "accept_privacy" => "true"
      }

      assert {:ok, activated_user} = Users.activate(token, attrs)
      assert activated_user.id == user.id
      refute is_nil(Repo.reload(activated_user).confirmed_at)
      assert Repo.get_by(EmailPasswordIdentityModel, user_id: user.id)
    end

    test "rejects mismatched password confirmation", %{token: token} do
      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "different",
        "accept_terms" => "true",
        "accept_privacy" => "true"
      }

      assert {:error, changeset} = Users.activate(token, attrs)
      assert "does not match password" in errors_on(changeset).password_confirmation
    end

    test "rejects when terms not accepted", %{token: token} do
      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "supersecret",
        "accept_terms" => "false",
        "accept_privacy" => "true"
      }

      assert {:error, changeset} = Users.activate(token, attrs)
      assert "you must accept the terms" in errors_on(changeset).accept_terms
    end

    test "rejects unknown token" do
      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "supersecret",
        "accept_terms" => "true",
        "accept_privacy" => "true"
      }

      assert {:error, :invalid_token} = Users.activate("garbage-token", attrs)
    end

    test "token cannot be reused", %{user: user, token: token} do
      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "supersecret",
        "accept_terms" => "true",
        "accept_privacy" => "true"
      }

      assert {:ok, _} = Users.activate(token, attrs)
      assert {:error, :invalid_token} = Users.activate(token, attrs)
      assert Users.activated?(Users.get_user!(user.id))
    end
  end

  describe "reissue_activation_token/1" do
    test "issues a new token and invalidates the previous one" do
      {:ok, %{user: user, token: old_token}} =
        Users.register_with_email("reissue@example.com")

      {:ok, new_token} = Users.reissue_activation_token(user)

      assert new_token != old_token

      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "supersecret",
        "accept_terms" => "true",
        "accept_privacy" => "true"
      }

      assert {:error, :invalid_token} = Users.activate(old_token, attrs)
      assert {:ok, _} = Users.activate(new_token, attrs)
    end
  end

  describe "authenticate_with_password/2" do
    setup do
      {:ok, %{user: user, token: token}} = Users.register_with_email("auth@example.com")

      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "supersecret",
        "accept_terms" => "true",
        "accept_privacy" => "true"
      }

      {:ok, _} = Users.activate(token, attrs)
      %{user: user}
    end

    test "returns the user with correct password", %{user: user} do
      assert %UserModel{id: id} =
               Users.authenticate_with_password("auth@example.com", "supersecret")

      assert id == user.id
    end

    test "is case-insensitive on email", %{user: user} do
      assert %UserModel{id: id} =
               Users.authenticate_with_password("Auth@Example.COM", "supersecret")

      assert id == user.id
    end

    test "returns nil with wrong password" do
      assert is_nil(Users.authenticate_with_password("auth@example.com", "nope"))
    end

    test "returns nil for unknown email" do
      assert is_nil(Users.authenticate_with_password("ghost@example.com", "anything"))
    end

    test "returns nil for unactivated user (no password identity yet)" do
      {:ok, _} = Users.register_with_email("pending@example.com")
      assert is_nil(Users.authenticate_with_password("pending@example.com", "anything"))
    end
  end
end
