defmodule LotteWeb.OnboardingHTML do
  use LotteWeb, :html

  embed_templates "onboarding_html/*"

  def services_text(%{company_profile: %{services: services}}) when is_list(services) do
    Enum.join(services, "\n")
  end

  def services_text(_), do: ""
end
