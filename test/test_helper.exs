ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(ElixirAwesome.Repo, :manual)
Application.ensure_all_started(:bypass)

defmodule ElixirAwesomeStubs do
  defmacro __using__(_) do
    quote do
      defp to_map(struct),
        do: Map.drop(struct, [:__meta__, :__struct__])

      @fragment_skipped "# H1 \n\n P \n\n P \n\n P \n\n -L \n\n"
      @fragment_cat "## Cat \n\nDescription\n\n"
      @fragment_project_valid "* [Project](https://github.com/user/repo) - Description\n\n"
      @fragment_project_invalid "* [Projecthttps://github.com/user/repo)Description"
      @fragment_unexpected_quote "\n\n> BQ \n\n"

      @source_empty ""
      @source_one_block "# Title \n eof"
      @source_no_cat @fragment_skipped <> "expext H2 \n\n expect P"
      @source_cat @fragment_skipped <> @fragment_cat
      @source_project_valid @source_cat <>
                              @fragment_project_valid
      @source_project_invalid @source_cat <>
                                @fragment_project_invalid

      @field_cat_name "Cat"
      @field_cat_description "<p>Description</p>"

      @field_project_name "Project"
      @field_project_url "https://github.com/user/repo"
      @field_project_description "<p>Description</p>"
      @field_project_last_commit ~N[2000-01-01 00:01:01]
      @field_project_stars_count 100

      @cat_from_source %{
        description: @field_cat_description,
        exist: true,
        name: @field_cat_name
      }
      @project_from_source %{
        category_name: @field_cat_name,
        description: @field_project_description,
        exist: true,
        name: @field_project_name,
        url: @field_project_url
      }
      @project_not_github %{
        category_name: @field_cat_name,
        description: @field_project_description,
        exist: true,
        name: @field_project_name,
        url: "http://example.com"
      }
      @project_without_meta %{
        category_name: @field_cat_name,
        description: @field_project_description,
        exist: true,
        last_commit: nil,
        name: @field_project_name,
        stars_count: -1,
        url: @field_project_url
      }
      @project_with_meta %{
        category_name: @field_cat_name,
        description: @field_project_description,
        exist: true,
        last_commit: @field_project_last_commit,
        name: @field_project_name,
        stars_count: @field_project_stars_count,
        url: @field_project_url
      }

      @github_api_meta ~s<{
        "stargazers_count": 100
      }>
      @github_api_commits ~s<[{
        "commit": {
          "author": {
            "date": "2000-01-01T00:01:01Z"
          }
        }
      }]>
    end
  end
end
