defmodule MoatDbc do
  @moduledoc """
  Moat database connector.

  MoatDbc provides a convenience method to connect to Moat's
  Snowflake database.

  ## Installation

  Add `:moat_dbc` as a dependency in your `mix.exs`:

    `{:moat_dbc, git: "https://github.com/mckuzyk/moat_dbc.git", tag: "0.1.1"}`

  In Livebook, you must additionally download the snowflake driver:

  ```
  Mix.Install(
    [
      {:moat_dbc, git: "https://github.com/mckuzyk/moat_dbc.git", tag: "0.1.0"}
    ],
    config: [adbc: [drivers: [:snowflake]]]
  )
  ```
  """

  @doc """
  Create a connection to snowflake.

  Returns an Adbc.Connection process.
  """
  def connect() do
    aws_keys = MoatDbc.AWS.get_sso_keys()
    client = apply(AWS.Client, :create, Tuple.to_list(aws_keys))

    {:ok, data, _response} =
      AWS.SecretsManager.get_secret_value(
        client,
        %{"SecretId" => "research-db"}
      )

    secrets = data["SecretString"] |> Jason.decode!()

    {:ok, ssm_data, _response} =
      AWS.SSM.get_parameter(
        client,
        %{"Name" => secrets["snowflake"]["private_key_arn"]}
      )

    key_text = ssm_data["Parameter"]["Value"]
    pem_dir = make_pem_cache()
    pem_path = Path.join(pem_dir, "snowflake.pem")
    File.write(pem_path, key_text)

    kw = [
      {:"adbc.snowflake.sql.auth_type", "auth_jwt"},
      {:"adbc.snowflake.sql.account", secrets["snowflake"]["account"]},
      {:"adbc.snowflake.sql.warehouse", secrets["snowflake"]["warehouse"]},
      {:driver, :snowflake},
      {:"adbc.snowflake.sql.client_option.jwt_private_key", pem_path},
      {:username, secrets["snowflake"]["user"]}
    ]

    {:ok, db} = Adbc.Database.start_link(kw)
    {:ok, conn} = Adbc.Connection.start_link(database: db)
    conn
  end

  defp make_pem_cache do
    path = Path.expand("~/.cache/moat_dbc")
    File.mkdir_p!(path)
    path
  end
end
