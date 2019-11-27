defmodule ElixirAwesomeWeb.ProjectController do
  use ElixirAwesomeWeb, :controller

  import ElixirAwesome.Projects, only: [cats_with_projects: 2]
  import ElixirAwesome.Projects.Crawler, only: [last_update: 1]

  defp regex(search) do
    import Regex, only: [compile: 2]

    with true <- is_binary(search),
         false <- search == "",
         {:ok, re} <- compile(search, "i") do
      re
    else
      _ -> nil
    end
  end

  defp last_update do
    case last_update(:meta) do
      [{_, datetime}] -> datetime
      _ -> nil
    end
  end

  def index(conn, params) do
    search = params["search"]
    stars = params["min_stars"]
    cats = cats_with_projects(stars, search)

    render(conn, "index.html",
      cats: cats,
      stars: stars,
      search: search,
      re: regex(search),
      last_update: last_update()
    )
  end
end
