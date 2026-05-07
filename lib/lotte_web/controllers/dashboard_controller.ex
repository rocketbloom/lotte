defmodule LotteWeb.DashboardController do
  use LotteWeb, :controller

  alias Lotte.Tenants

  def index(conn, _params) do
    user = conn.assigns.current_user

    if user.tenant_id do
      tenant = Tenants.get_tenant(user.tenant_id)
      render(conn, :index, user: user, tenant: tenant)
    else
      redirect(conn, to: ~p"/onboarding/company")
    end
  end
end
