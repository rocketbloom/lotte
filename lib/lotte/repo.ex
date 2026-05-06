defmodule Lotte.Repo do
  use Ecto.Repo,
    otp_app: :lotte,
    adapter: Ecto.Adapters.Postgres
end
