defmodule ElixirAwesomeWeb.ProjectControllerTest do
  use ExUnit.Case
  use ElixirAwesomeStubs
  use Phoenix.ConnTest

  alias ElixirAwesomeWeb.Router.Helpers, as: Routes
  alias ElixirAwesome.Repo

  @endpoint ElixirAwesomeWeb.Endpoint

  import Phoenix.ConnTest
  import ElixirAwesome.Projects
  import Ecto.Adapters.SQL.Sandbox, only: [checkout: 1, mode: 2]

  setup do
    checkout(Repo)
    mode(Repo, {:shared, self()})

    query()
    |> upsert_categories([@cat_from_source])
    |> upsert_projects([@project_with_meta])
    |> run()

    {:ok, conn: build_conn()}
  end

  test "all data", %{conn: conn} do
    html =
      get(conn, Routes.project_path(conn, :index))
      |> html_response(200)

    assert html =~ @field_cat_description
    assert html =~ @field_cat_name
    assert html =~ @field_project_description
  end
  
  test "min stars -1, ever mathed", %{conn: conn} do
    html =
      get(conn, Routes.project_path(conn, :index, %{"min_stars" => "-1"}))
      |> html_response(200)

    assert html =~ @field_cat_name
    assert html =~ @field_cat_description
    assert html =~ @field_project_description
  end
  
  test "min stars 2147483647, never mathed", %{conn: conn} do
    html =
      get(conn, Routes.project_path(conn, :index, %{"min_stars" => "2147483647"}))
      |> html_response(200)

    assert html =~ @field_cat_name
    refute html =~ @field_cat_description
    refute html =~ @field_project_description
  end
  
  test "search \"neverMat4InG#$%^_mathing\", not mathed", %{conn: conn} do
    html =
      get(conn, Routes.project_path(conn, :index, %{"search" => "neverMat4InG#$%^_mathing"}))
      |> html_response(200)

    assert html =~ @field_cat_name
    refute html =~ @field_cat_description
    refute html =~ @field_project_description
  end
  
  test "search ever_mathed, mathed", %{conn: conn} do
    html =
      get(conn, Routes.project_path(conn, :index, %{"search" => @field_project_name}))
      |> html_response(200)

    assert html =~ @field_cat_name
    assert html =~ @field_cat_description
    assert html =~ @field_project_description
  end
end
