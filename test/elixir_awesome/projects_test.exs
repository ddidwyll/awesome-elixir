defmodule ElixirAwesome.ProjectsTest do
  use ExUnit.Case
  use ElixirAwesomeStubs

  import ElixirAwesome.Projects

  setup do
    import Ecto.Adapters.SQL.Sandbox, only: [checkout: 1]

    checkout(ElixirAwesome.Repo)
  end

  test "insert valid project with non-existent category_name" do
    assert_raise Postgrex.Error, ~r/^ERROR 23503/, fn ->
      query() |> upsert_projects([@project_from_source]) |> run()
    end
  end

  test "full data life cycle" do
    assert {:ok, %{ups_c: {1, nil}, ups_p: {1, [returned_project]}}} =
             query()
             |> upsert_categories([@cat_from_source])
             |> upsert_projects([@project_from_source])
             |> run()

    assert @project_without_meta = to_map(returned_project)

    # retrieve saved data
    assert [category] = cats_with_projects(nil, nil)

    # check saved category
    assert @field_cat_name = category.name
    assert @field_cat_description = category.description
    assert true = category.exist

    # check saved project
    assert [project] = category.projects
    assert @project_without_meta = to_map(project)

    # invalidate all data
    assert {:ok, %{inv_c: {1, nil}, inv_p: {1, nil}}} =
             query() |> invalidate_all() |> run()

    # check that all data invalidated
    assert [] = cats_with_projects(nil, nil)

    # update category
    assert {:ok, %{ups_c: {1, nil}}} =
             query()
             |> upsert_categories([%{@cat_from_source | exist: true}])
             |> run()

    # retrieve updated category
    assert [category_updated] = cats_with_projects(nil, nil)
    assert @cat_from_source = to_map(category_updated)

    # update project (only last_commit and exist)
    assert {:ok, %{ups_p: {1, [project_updated]}}} =
             query()
             |> upsert_projects([@project_with_meta], [
               :last_commit,
               :exist
             ])
             |> run()

    assert @field_project_last_commit = project_updated.last_commit
    assert true = project_updated.exist

    # update project with new stars_count
    assert {:ok, %{ups_p: {1, [project_with_meta]}}} =
             query()
             |> upsert_projects([@project_with_meta])
             |> run()

    assert @project_with_meta = to_map(project_with_meta)

    # check min stars constraint
    assert [%{projects: [%{name: "Project"}]}] =
             cats_with_projects("100", nil)

    assert [%{projects: []}] = cats_with_projects("2147483647", nil)

    # check substring search constraint
    assert [%{projects: [%{name: "Project"}]}] =
             cats_with_projects(nil, "Descr")

    assert [%{projects: [%{name: "Project"}]}] =
             cats_with_projects(nil, "ipt")

    assert [%{projects: [%{name: "Project"}]}] =
             cats_with_projects(nil, "cat")

    assert [%{projects: []}] = cats_with_projects(nil, "neverMat4InG%$%")
  end
end
