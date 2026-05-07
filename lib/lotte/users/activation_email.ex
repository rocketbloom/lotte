defmodule Lotte.Users.ActivationEmail do
  @moduledoc """
  Builds the email containing the activation link.
  Composition is split from delivery — `Lotte.Users` decides when to send.
  """
  import Swoosh.Email

  @from {"Lotte", "noreply@lotte-test.fly.dev"}

  def build(email, activation_url) when is_binary(email) and is_binary(activation_url) do
    new()
    |> from(@from)
    |> to(email)
    |> subject("Activate your Lotte account")
    |> text_body(text_body(activation_url))
    |> html_body(html_body(activation_url))
  end

  defp text_body(url) do
    """
    Welcome to Lotte!

    To finish setting up your account (set a password and accept terms),
    open the link below. You can also continue exploring the demo for now
    and activate later.

    #{url}

    If you didn't request this, you can ignore this email.
    """
  end

  defp html_body(url) do
    """
    <p>Welcome to <strong>Lotte</strong>!</p>
    <p>To finish setting up your account (set a password and accept terms),
    click the link below. You can also continue exploring the demo for now
    and activate later.</p>
    <p><a href="#{url}">#{url}</a></p>
    <p style="color:#888;font-size:12px">If you didn't request this, you can ignore this email.</p>
    """
  end
end
