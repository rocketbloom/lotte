defmodule Lotte.TenantsTest do
  use Lotte.DataCase, async: true

  alias Lotte.Tenants
  alias Lotte.Tenants.TenantModel

  describe "create_tenant/1" do
    test "accepts the Flowise + tenant-config fields" do
      assert {:ok, tenant} =
               Tenants.create_tenant(%{
                 name: "Acme Practice",
                 flowise_chatflow_id: "cf-abc-123",
                 calendar_url: "https://cal.example.com/acme",
                 default_language: "nl"
               })

      assert tenant.flowise_chatflow_id == "cf-abc-123"
      assert tenant.calendar_url == "https://cal.example.com/acme"
      assert tenant.default_language == "nl"
    end

    test "all Flowise fields are optional" do
      assert {:ok, tenant} = Tenants.create_tenant(%{name: "Bare Tenant"})
      assert is_nil(tenant.flowise_chatflow_id)
      assert is_nil(tenant.calendar_url)
      assert is_nil(tenant.default_language)
    end
  end

  describe "update_tenant/2" do
    test "can set Flowise fields after creation" do
      {:ok, tenant} = Tenants.create_tenant(%{name: "Later Update"})

      assert {:ok, updated} =
               Tenants.update_tenant(tenant, %{
                 flowise_chatflow_id: "cf-xyz",
                 default_language: "en"
               })

      assert updated.flowise_chatflow_id == "cf-xyz"
      assert updated.default_language == "en"
      assert %TenantModel{} = updated
    end
  end
end
