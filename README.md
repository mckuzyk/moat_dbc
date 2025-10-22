# MoatDbc

Moat database connector.

MoatDbc provides a convenience method to connect to Moat's
Snowflake database.

## Installation

Add `:moat_dbc` as a dependency in your `mix.exs`:

  {:moat_dbc, git: "https://github.com/mckuzyk/moat_dbc.git", tag: "0.1.1"}

In Livebook, you must additionally download the snowflake driver:

```
Mix.Install(
  [
    {:moat_dbc, git: "https://github.com/mckuzyk/moat_dbc.git", tag: "0.1.0"}
  ],
  config: [adbc: [drivers: [:snowflake]]]
)
```
