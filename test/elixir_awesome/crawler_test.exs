defmodule ElixirAwesome.Projects.CrawlerTest do
  use ExUnit.Case
  use ElixirAwesomeStubs

  alias ElixirAwesome.Repo

  import ElixirAwesome.Projects
  import ElixirAwesome.Projects.Crawler

  import IO, only: [puts: 1]
  import ExUnit.CaptureLog, only: [capture_log: 1]
  import Application, only: [put_env: 3]
  import Bypass, only: [open: 0, expect: 4, down: 1]
  import Ecto.Adapters.SQL.Sandbox, only: [checkout: 1, mode: 2]

  import Plug.Conn,
    only: [resp: 3, put_resp_header: 3, get_req_header: 2]

  setup do
    bypass = open()
    checkout(Repo)
    mode(Repo, {:shared, self()})

    mock_url = "http://localhost:#{bypass.port}"

    put_env(:elixir_awesome, :parse_url, mock_url <> "/source.md")
    put_env(:elixir_awesome, :github_api, mock_url)
    put_env(:elixir_awesome, :mod_times_file, "test_dets")

    on_exit(fn -> :dets.delete_all_objects(:mod_times) end)

    {:ok, bypass: bypass}
  end

  defp log(timeout \\ 10000) do
    puts("Please wait #{timeout}ms")

    capture_log(fn ->
      go()
      :timer.sleep(timeout)
    end)
  end

  defp if_mod_since do
    import ElixirAwesome.Projects.Helpers
    import String, only: [slice: 3]

    now_http()
    |> slice(0, 16)
  end

  defp last_mod() do
    import :dets, only: [lookup: 2]

    %{
      meta: lookup(:mod_times, :meta)[:meta],
      fetch: lookup(:mod_times, :fetch)[:fetch]
    }
  end

  test "collect all data", %{bypass: bypass} do
    expect(bypass, "GET", "/source.md", fn conn ->
      etag = get_req_header(conn, "if-none-match")

      if etag == ["fake_etag"] do
        resp(conn, 304, "")
      else
        conn
        |> put_resp_header("ETag", "fake_etag")
        |> resp(200, @source_project_valid)
      end
    end)

    expect(bypass, "GET", "/user/repo", fn conn ->
      last_mod = get_req_header(conn, "if-modified-since")

      if last_mod != [] do
        resp(conn, 304, "")
      else
        resp(conn, 200, @github_api_meta)
      end
    end)

    expect(bypass, "GET", "/user/repo/commits", fn conn ->
      last_mod = get_req_header(conn, "if-modified-since")

      if last_mod != [] do
        resp(conn, 304, "")
      else
        resp(conn, 200, @github_api_commits)
      end
    end)

    # run crawler
    assert "" = log()

    # retrieve and check collected data from db
    assert [category] = cats_with_projects(nil, nil)
    assert @field_cat_name = category.name
    assert @field_cat_description = category.description
    assert [project] = category.projects
    assert @project_with_meta = to_map(project)

    # get and check last modification info
    assert {_, [{_, etag_fetch}]} = last_mod().fetch
    assert "fake_etag" = etag_fetch
    assert [{_, lu_meta}] = last_mod().meta
    assert lu_meta =~ if_mod_since()

    # second run
    assert "" = log()
    assert [{_, lu_meta_second}] = last_mod().meta
    assert lu_meta_second =~ if_mod_since()
    assert lu_meta_second > lu_meta
  end

  test "no connection", %{bypass: bypass} do
    down(bypass)

    # run crawler
    log = log(100)
    assert log =~ "Fetch error, econnrefused"
  end

  test "rate limit, sleep", %{bypass: bypass} do
    expect(bypass, "GET", "/source.md", fn conn ->
      resp(conn, 200, @source_project_valid)
    end)

    expect(bypass, "GET", "/user/repo/commits", fn conn ->
      resp(conn, 200, @github_api_commits)
    end)

    expect(bypass, "GET", "/user/repo", fn conn ->
      auth = get_req_header(conn, "authorization")

      if ["Basic dGVzdDp0ZXN0"] == auth do
        resp(conn, 200, @github_api_meta)
      else
        conn
        |> put_resp_header("X-RateLimit-Remaining", "0")
        |> put_resp_header("X-RateLimit-Reset", "1000000000")
        |> resp(403, "")
      end
    end)

    # without github creds
    log = log()
    assert log =~ "Rate limit, need wait 3600 seconds"

    put_env(:elixir_awesome, :github_login, "test")
    put_env(:elixir_awesome, :github_pass, "test")

    # with github creds
    assert "" = log()
  end
end
