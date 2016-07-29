defmodule ArcgisGeocode.Authenticator do

  @moduledoc """
  Provides the ability to request an access token from the
  [ArcGIS World Geocoding Service APIs](https://developers.arcgis.com/rest/geocode/api-reference/geocoding-authenticate-a-request.htm).
  """

  @auth_url "https://www.arcgis.com/sharing/rest/oauth2/token"
  @grant_type "client_credentials"

  @doc """
  Returns an access token from the `ArcgisGeocode.Cache` if one exists and is not yet expired.

  When a token does not yet exist in the cache or the existing token is expired, an authentication request is made and
  the resultant token is stored in the `ArcgisGeocode.Cache` for use in subsequent geocoding requests.
  """
  @spec get_token() :: {atom, String.t}
  def get_token do
    case ArcgisGeocode.Cache.get do
      %{"access_token" => access_token, "expiration" => expiration} ->
        case expired?(expiration) do
          false -> {:ok, access_token}
          true -> authenticate
        end
      %{} -> authenticate
    end
  end

  @doc """
  Requests an access token from the ArcGIS API for use in geocoding requests.

  For successful requests, the resultant access token is stored in the `ArcgisGeocode.Cache` Agent.
  """
  @spec authenticate() :: {atom, String.t}
  def authenticate do
    body = {:form, [{:client_id, Application.get_env(:arcgis_geocode, :client_id)},
                    {:client_secret, Application.get_env(:arcgis_geocode, :client_secret)},
                    {:grant_type, @grant_type}]}
    case HTTPoison.post(@auth_url, body) do
      {:error, response} -> {:error, %{"error" => %{"reason" => response.reason}}}
      {:ok, response} -> Poison.Parser.parse!(response.body) |> process_authentication_response
    end
  end


  defp process_authentication_response(%{"error" => error}), do: {:error, error["message"]}
  defp process_authentication_response(%{"access_token" => access_token, "expires_in" => expires_in}) do
    ArcgisGeocode.Cache.put(access_token, process_expiration(expires_in))
    {:ok, access_token}
  end

  defp process_expiration(seconds) when is_number(seconds) do
    Timex.DateTime.now |> Timex.DateTime.shift(seconds: seconds - 300)
  end

  defp expired?(nil), do: true
  defp expired?(expiration), do: Timex.DateTime.diff(Timex.DateTime.now, expiration) <= 0

end
