defmodule Lotte.KnowledgeTest do
  use Lotte.DataCase, async: true

  alias Lotte.Knowledge
  alias Lotte.Tenants

  setup do
    {:ok, tenant} = Tenants.create_tenant(%{name: "Acme Practice"})
    %{tenant: tenant}
  end

  describe "create_entry/1" do
    test "creates with required fields", %{tenant: tenant} do
      assert {:ok, entry} =
               Knowledge.create_entry(%{
                 tenant_id: tenant.id,
                 category: "service",
                 title: "Massage",
                 content: "30-min therapeutic massage"
               })

      assert entry.tenant_id == tenant.id
      assert entry.category == "service"
      assert entry.language == "all"
    end

    test "rejects unknown category", %{tenant: tenant} do
      assert {:error, changeset} =
               Knowledge.create_entry(%{
                 tenant_id: tenant.id,
                 category: "bogus",
                 title: "X",
                 content: "Y"
               })

      assert "is invalid" in errors_on(changeset).category
    end

    test "rejects unknown language", %{tenant: tenant} do
      assert {:error, changeset} =
               Knowledge.create_entry(%{
                 tenant_id: tenant.id,
                 category: "faq",
                 title: "X",
                 content: "Y",
                 language: "de"
               })

      assert "is invalid" in errors_on(changeset).language
    end

    test "rejects when content missing", %{tenant: tenant} do
      assert {:error, changeset} =
               Knowledge.create_entry(%{
                 tenant_id: tenant.id,
                 category: "service",
                 title: "X"
               })

      assert "can't be blank" in errors_on(changeset).content
    end
  end

  describe "list_entries/2" do
    setup %{tenant: tenant} do
      {:ok, t2} = Tenants.create_tenant(%{name: "Other Practice"})

      {:ok, e1} =
        Knowledge.create_entry(%{
          tenant_id: tenant.id,
          category: "service",
          title: "S1",
          content: "C1",
          language: "nl"
        })

      {:ok, e2} =
        Knowledge.create_entry(%{
          tenant_id: tenant.id,
          category: "faq",
          title: "F1",
          content: "C2",
          language: "all"
        })

      {:ok, _other} =
        Knowledge.create_entry(%{
          tenant_id: t2.id,
          category: "service",
          title: "Other S",
          content: "Other"
        })

      %{tenant: tenant, e1: e1, e2: e2}
    end

    test "returns only entries for the given tenant", %{tenant: tenant, e1: e1, e2: e2} do
      ids = Knowledge.list_entries(tenant.id) |> Enum.map(& &1.id) |> MapSet.new()
      assert ids == MapSet.new([e1.id, e2.id])
    end

    test "filters by category", %{tenant: tenant, e1: e1} do
      assert [returned] = Knowledge.list_entries(tenant.id, category: "service")
      assert returned.id == e1.id
    end

    test "filters by language and includes language=all", %{tenant: tenant, e1: e1, e2: e2} do
      ids = Knowledge.list_entries(tenant.id, language: "nl") |> Enum.map(& &1.id) |> MapSet.new()
      assert ids == MapSet.new([e1.id, e2.id])

      ids = Knowledge.list_entries(tenant.id, language: "en") |> Enum.map(& &1.id) |> MapSet.new()
      assert ids == MapSet.new([e2.id])
    end
  end

  describe "update_entry/2 and delete_entry/1" do
    test "round-trip", %{tenant: tenant} do
      {:ok, entry} =
        Knowledge.create_entry(%{
          tenant_id: tenant.id,
          category: "service",
          title: "Old",
          content: "Old"
        })

      assert {:ok, updated} = Knowledge.update_entry(entry, %{title: "New"})
      assert updated.title == "New"

      assert {:ok, _} = Knowledge.delete_entry(updated)
      assert is_nil(Knowledge.get_entry(updated.id))
    end
  end
end
