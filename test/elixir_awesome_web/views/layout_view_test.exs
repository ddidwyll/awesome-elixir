defmodule ElixirAwesomeWeb.ProjectViewTest do
  use ExUnit.Case
  use ElixirAwesomeStubs
  use Phoenix.ConnTest

  alias ElixirAwesomeWeb.Router.Helpers, as: Routes
  alias ElixirAwesome.Repo

  @endpoint ElixirAwesomeWeb.Endpoint

  import Phoenix.ConnTest
  import ElixirAwesome.Projects
  import ElixirAwesomeWeb.ProjectView
  import Application, only: [put_env: 3]
  import Ecto.Adapters.SQL.Sandbox, only: [checkout: 1, mode: 2]

  setup do
    checkout(Repo)
    mode(Repo, {:shared, self()})

    query()
    |> upsert_categories([@cat_from_source])
    |> upsert_projects([@project_with_meta])
    |> run()

    put_env(:elixir_awesome, :mod_times_file, "test_dets")
    on_exit(fn -> :dets.delete_all_objects(:mod_times) end)

    {:ok, conn: build_conn()}
  end

  test "format last_commit field", %{conn: conn} do
    html =
      get(conn, Routes.project_path(conn, :index))
      |> html_response(200)

    last_commit_formatted = days_ago(@field_project_last_commit)

    assert html =~ last_commit_formatted
  end

  test "format last update footer", %{conn: conn} do
    :dets.insert(:mod_times, {:meta, [{nil, "fake_last_update"}]})

    html =
      get(conn, Routes.project_path(conn, :index))
      |> html_response(200)

    assert html =~ "fake_last_update"
  end

  test "format highlighted search substr", %{conn: conn} do
    import String, only: [slice: 3]
    import Regex, only: [compile!: 1]

    substr = slice(@field_project_description, 1, 3)
    re = compile!(substr)

    html =
      get(conn, Routes.project_path(conn, :index, %{"search" => substr}))
      |> html_response(200)

    highlighted = highlight(substr, re)

    assert html =~ highlighted
  end
end
