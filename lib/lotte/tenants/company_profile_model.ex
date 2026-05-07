defmodule Lotte.Tenants.CompanyProfileModel do
  @moduledoc """
  Embedded schema for the rich Tenant onboarding fields.

  Stored as a JSON map on `tenant.company_profile`. We start as one
  loose document so we can iterate; promote to dedicated columns once
  query patterns demand it.

  All fields are optional — onboarding fills them in across steps and
  the user can skip.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :description, :string
    field :services, {:array, :string}, default: []
    field :website_url, :string
    field :opening_hours, :string
    field :address, :string
    field :tone, :string
  end

  @about_fields [:description, :services, :website_url]
  @operate_fields [:opening_hours, :address, :tone]

  def about_changeset(profile, attrs) do
    attrs = normalize_services_input(attrs)

    profile
    |> cast(attrs, @about_fields)
    |> normalize_services()
    |> validate_url(:website_url)
  end

  defp normalize_services_input(%{"services" => raw} = attrs) when is_binary(raw) do
    list = raw |> String.split(~r/\R/) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
    Map.put(attrs, "services", list)
  end

  defp normalize_services_input(attrs), do: attrs

  def operate_changeset(profile, attrs) do
    cast(profile, attrs, @operate_fields)
  end

  defp normalize_services(changeset) do
    case get_change(changeset, :services) do
      nil ->
        changeset

      list when is_list(list) ->
        cleaned =
          list
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        put_change(changeset, :services, cleaned)
    end
  end

  defp validate_url(changeset, field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      "" ->
        put_change(changeset, field, nil)

      url ->
        if String.match?(url, ~r{^https?://[^\s]+$}) do
          changeset
        else
          add_error(changeset, field, "must start with http:// or https://")
        end
    end
  end
end
