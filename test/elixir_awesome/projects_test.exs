defmodule ElixirAwesome.ProjectsTest do
  use ElixirAwesome.DataCase

  alias ElixirAwesome.Projects

  describe "projects" do
    alias ElixirAwesome.Projects.Project

    @valid_attrs %{
      category: "some category",
      description: "some description",
      exist: true,
      last_commit: ~N[2010-04-17 14:00:00],
      name: "some name",
      stars_count: 42,
      url: "some url"
    }
    @update_attrs %{
      category: "some updated category",
      description: "some updated description",
      exist: false,
      last_commit: ~N[2011-05-18 15:01:01],
      name: "some updated name",
      stars_count: 43,
      url: "some updated url"
    }
    @invalid_attrs %{
      category: nil,
      description: nil,
      exist: nil,
      last_commit: nil,
      name: nil,
      stars_count: nil,
      url: nil
    }

    def project_fixture(attrs \\ %{}) do
      {:ok, project} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Projects.create_project()

      project
    end

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Projects.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Projects.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      assert {:ok, %Project{} = project} =
               Projects.create_project(@valid_attrs)

      assert project.category == "some category"
      assert project.description == "some description"
      assert project.exist == true
      assert project.last_commit == ~N[2010-04-17 14:00:00]
      assert project.name == "some name"
      assert project.stars_count == 42
      assert project.url == "some url"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Projects.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()

      assert {:ok, %Project{} = project} =
               Projects.update_project(project, @update_attrs)

      assert project.category == "some updated category"
      assert project.description == "some updated description"
      assert project.exist == false
      assert project.last_commit == ~N[2011-05-18 15:01:01]
      assert project.name == "some updated name"
      assert project.stars_count == 43
      assert project.url == "some updated url"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Projects.update_project(project, @invalid_attrs)

      assert project == Projects.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projects.delete_project(project)

      assert_raise Ecto.NoResultsError, fn ->
        Projects.get_project!(project.id)
      end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end

  describe "categories" do
    alias ElixirAwesome.Projects.Category

    @valid_attrs %{
      description: "some description",
      exist: true,
      name: "some name"
    }
    @update_attrs %{
      description: "some updated description",
      exist: false,
      name: "some updated name"
    }
    @invalid_attrs %{description: nil, exist: nil, name: nil}

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Projects.create_category()

      category
    end

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Projects.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Projects.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} =
               Projects.create_category(@valid_attrs)

      assert category.description == "some description"
      assert category.exist == true
      assert category.name == "some name"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Projects.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()

      assert {:ok, %Category{} = category} =
               Projects.update_category(category, @update_attrs)

      assert category.description == "some updated description"
      assert category.exist == false
      assert category.name == "some updated name"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Projects.update_category(category, @invalid_attrs)

      assert category == Projects.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Projects.delete_category(category)

      assert_raise Ecto.NoResultsError, fn ->
        Projects.get_category!(category.id)
      end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Projects.change_category(category)
    end
  end
end
