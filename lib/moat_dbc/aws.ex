defmodule MoatDbc.AWS do
  def get_access_token() do
    access_token =
      Path.expand("~/.aws/sso/cache/")
      |> Path.join("*.json")
      |> Path.wildcard()
      |> Enum.map(&File.read!/1)
      |> Enum.map(&Jason.decode!/1)
      |> Enum.map(&Map.get(&1, "accessToken"))
      |> Enum.filter(&(&1 != nil))
      |> Enum.at(0)

    if access_token == nil do
      {:error, "No access tokens found in ~/.aws/sso/cache/"}
    else
      {:ok, access_token}
    end
  end

  def get_sso_config() do
    "~/.aws/config"
    |> Path.expand()
    |> ConfigParser.parse_file()
  end

  def get_sso_keys() do
    {:ok, access_token} = get_access_token()
    {:ok, config} = get_sso_config()

    {output, exit_code} =
      System.cmd(
        "/usr/local/bin/aws",
        [
          "sso",
          "get-role-credentials",
          "--account-id",
          config["default"]["sso_account_id"],
          "--role-name",
          config["default"]["sso_role_name"],
          "--access-token",
          access_token,
          "--region",
          config["sso-session moat-sso"]["sso_region"]
        ],
        stderr_to_stdout: true
      )

    if exit_code == 0 do
      data = Jason.decode!(output)["roleCredentials"]

      {
        data["accessKeyId"],
        data["secretAccessKey"],
        data["sessionToken"],
        config["sso-session moat-sso"]["sso_region"]
      }
    else
      {:error, output}
    end
  end
end
