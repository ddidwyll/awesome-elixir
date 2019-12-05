defmodule ElixirAwesome.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias ElixirAwesome.Repo

  alias ElixirAwesome.Projects.Project, as: Prj
  alias ElixirAwesome.Projects.Category, as: Cat

  defp where_stars(query, stars) do
    import Ecto.Query, only: [where: 3]
    import Integer, only: [parse: 1]

    with false <- is_nil(stars),
         false <- stars == "",
         {stars, _} <- parse(stars) do
      where(query, [p], p.stars_count >= ^stars)
    else
      _ -> query
    end
  end

  defp where_search(query, search) do
    import Ecto.Query, only: [where: 3]

    if is_binary(search) && search != "" do
      str = "%#{search}%"

      where(
        query,
        [p],
        ilike(p.name, ^str) or
          ilike(p.description, ^str) or
          ilike(p.category_name, ^str)
      )
    else
      query
    end
  end

  def cats_with_projects(min_stars, search) do
    import Ecto.Query, only: [from: 2]
    import Repo, only: [all: 1]

    subquery =
      from(Prj, where: [exist: true])
      |> where_stars(min_stars)
      |> where_search(search)

    query =
      from c in Cat,
        where: [exist: true],
        left_join: p in ^subquery,
        on: [category_name: c.name],
        order_by: [c.name, p.name],
        preload: [projects: p]

    all(query)
  end

  def query, do: Ecto.Multi.new()
  def run(query), do: Repo.transaction(query)

  def invalidate_all(query) do
    import Ecto.Multi, only: [update_all: 4]

    query
    |> update_all(:inv_c, Cat, set: [exist: false])
    |> update_all(:inv_p, Prj, set: [exist: false])
  end

  def upsert_categories(query, categories) do
    import Ecto.Multi, only: [insert_all: 5]

    query
    |> insert_all(:ups_c, Cat, categories,
      on_conflict: :replace_all,
      conflict_target: :name
    )
  end

  def upsert_projects(query, projects, fields \\ nil) do
    import Ecto.Multi, only: [insert_all: 5]

    replace =
      if is_list(fields),
        do: {:replace, fields},
        else: :replace_all

    query
    |> insert_all(:ups_p, Prj, projects,
      on_conflict: replace,
      conflict_target: :url,
      returning: true
    )
  end
end
