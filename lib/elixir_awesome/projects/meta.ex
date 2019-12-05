defmodule ElixirAwesome.Projects.Meta do
  @moduledoc false

  import Logger, only: [info: 1, warn: 1]

  defp is_github(project_url) do
    import String, only: [split: 2]

    case split(project_url, "github.com") do
      [_, repo] -> {:ok, repo}
      _ -> {:skip, "Not github repo, cannot get meta"}
    end
  end

  defp github_api(repo, header) do
    alias ElixirAwesome.Projects.Helpers
    alias HTTPoison.Response, as: R
    alias HTTPoison.Error, as: E

    import Application, only: [get_env: 2]
    import Helpers, only: [set_headers: 1]
    import HTTPoison, only: [get: 3]

    url = get_env(:elixir_awesome, :github_api) <> repo

    info("Try to get meta from #{url}")

    case get(url, set_headers(header),
           params: [page: 1, per_page: 1],
           follow_redirect: true
         ) do
      {:ok, %R{status_code: 304}} ->
        :not_modified

      {:ok, %R{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %R{status_code: 403, headers: headers}} ->
        is_sleep(headers)

      {:ok, %R{status_code: 404}} ->
        {:delete, "Project not found"}

      {:error, %E{reason: reason}} ->
        {:shedule, inspect(reason)}

      _ ->
        {:shedule, "Something went wrong"}
    end
  end

  defp is_sleep(headers) do
    alias ElixirAwesome.Projects.Helpers
    import Helpers, only: [get_header: 2]
    import Integer, only: [parse: 1]
    import :os, only: [system_time: 1]

    with limit <- get_header(headers, "X-RateLimit-Remaining"),
         true <- limit == "0",
         reset <- get_header(headers, "X-RateLimit-Reset"),
         {unix, _} <- parse(reset || "") do
      now = system_time(:second)

      if unix > now do
        {:sleep, unix - now}
      else
        {:sleep, 3600}
      end
    else
      _ -> {:skip, "Forbidden"}
    end
  end

  defp parse_stars({:ok, json}, project) do
    import Jason, only: [decode: 1]

    case decode(json) do
      {:ok, %{"stargazers_count" => stars_count}} ->
        {
          :ok,
          %{project | stars_count: stars_count},
          project.stars_count != stars_count
        }

      _ ->
        {:skip, "Cannot parse stars count, wrong json"}
    end
  end

  defp parse_stars(:not_modified, project), do: {:ok, project, false}
  defp parse_stars(error, _), do: error

  defp parse_commits({:ok, json}, project) do
    import Jason, only: [decode: 1]
    import NaiveDateTime, only: [from_iso8601: 1]

    with {:ok, [commit | _]} <- decode(json),
         %{"commit" => %{"author" => %{"date" => lc_date}}} <-
           commit,
         {:ok, result} <- from_iso8601(lc_date) do
      {
        :ok,
        %{project | last_commit: result},
        project.last_commit != result
      }
    else
      _ -> {:skip, "Cannot parse last commit date, wrong json"}
    end
  end

  defp parse_commits(:not_modified, project),
    do: {:ok, project, false}

  defp parse_commits(error, _), do: error

  defp iterate({[], _}, to_db, queue),
    do: {:eol, to_db, queue}

  defp iterate({[project | projects], header}, to_db, queue) do
    import Map, only: [drop: 2]

    p = drop(project, [:__meta__, :__struct__])

    with {:ok, repo} <- is_github(p.url),
         {:ok, p, st_updated} <-
           github_api(repo, header)
           |> parse_stars(p),
         {:ok, p, lc_updated} <-
           github_api(repo <> "/commits", header)
           |> parse_commits(p) do
      if st_updated || lc_updated do
        info("#{p.url}: meta updated")
        iterate({projects, header}, [p | to_db], queue)
      else
        info("#{p.url}: meta not modified")
        iterate({projects, header}, to_db, queue)
      end
    else
      {:shedule, error} ->
        warn("#{p.url}: #{error} (try again later)")
        iterate({projects, header}, to_db, [project | queue])

      {:skip, error} ->
        warn("#{p.url}: #{error} (project skipped)")
        iterate({projects, header}, to_db, queue)

      {:delete, error} ->
        warn("#{p.url}: #{error} (project deleted)")
        del = %{p | exist: false}
        iterate({projects, header}, [del | to_db], queue)

      {:sleep, wait} ->
        warn("Rate limit, need wait #{wait} seconds")
        new_queue = [project | projects] ++ queue
        {{:sleep, wait}, to_db, new_queue}
    end
  end

  def meta({projects, header}),
    do: iterate({projects, header}, [], [])
end
