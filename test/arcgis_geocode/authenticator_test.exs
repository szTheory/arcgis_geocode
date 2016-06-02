defmodule AuthenticatorTest do
  use ExUnit.Case, async: true
  doctest ArcgisGeocode.Authenticator

  alias ArcgisGeocode.Authenticator

  setup do
    ArcgisGeocode.Cache.clear
    :ok
  end

  test "authenticate returns an access token" do
    assert {:ok, _} = Authenticator.authenticate
  end

  test "get_token returns a cached token" do
    token = "secret!"
    expiration = Timex.DateTime.shift(Timex.DateTime.now, seconds: 200)

    refute Authenticator.get_token == {:ok, token}
    assert ArcgisGeocode.Cache.put(token, expiration) == :ok
    assert Authenticator.get_token == {:ok, token}
  end

end
