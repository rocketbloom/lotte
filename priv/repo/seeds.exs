# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Lotte.Repo.insert!(%Lotte.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Lotte.Repo
alias Lotte.Tenants

# Clean up existing test tenants
Repo.query!("DELETE FROM tenant WHERE slug IN ('demo', 'test-practice')")

# Create demo tenant
Tenants.create_tenant!(%{
  name: "Demo Practice",
  slug: "demo",
  subdomain: "demo",
  status: "active",
  settings: %{
    "timezone" => "Europe/Amsterdam",
    "language" => "en"
  }
})

# Create test tenant
Tenants.create_tenant!(%{
  name: "Test Healthcare Practice",
  slug: "test-practice",
  subdomain: "test",
  status: "active",
  settings: %{
    "timezone" => "Europe/Amsterdam",
    "language" => "en"
  }
})

IO.puts("✓ Seeded tenants")
