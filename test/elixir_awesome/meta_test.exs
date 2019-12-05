defmodule ElixirAwesome.Projects.MetaTest do
  use ExUnit.Case
  use ElixirAwesomeStubs

  import ExUnit.CaptureLog
  import ElixirAwesome.Projects.Meta
  import Application, only: [put_env: 3]
  import Plug.Conn, only: [resp: 3, put_resp_header: 3]
  import Bypass, only: [open: 0, expect: 2, expect: 4, down: 1]

  setup do
    bypass = open()
    mock_url = "http://localhost:#{bypass.port}"
    put_env(:elixir_awesome, :github_api, mock_url)

    {:ok, bypass: bypass}
  end

  defp meta, do: meta({[@project_without_meta], nil})
  defp log, do: capture_log(&meta/0)

  test "project not in github, skip" do
    assert {:eol, [], []} = meta({[@project_not_github], nil})

    assert capture_log(fn -> meta({[@project_not_github], nil}) end) =~
             "Not github repo, cannot get meta (project skipped)"
  end

  test "no connection, try all again", %{bypass: bypass} do
    down(bypass)

    assert {:eol, to_db, try_again} = meta()
    assert [] = to_db
    assert [@project_from_source] = try_again
    assert log() =~ ":econnrefused (try again later)"
  end

  test "server error, try all again", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 500, "")
    end)

    assert {:eol, [], [@project_from_source]} = meta()
    assert log() =~ "Something went wrong (try again later)"
  end

  test "valid meta, but wrong commits, try", %{bypass: bypass} do
    expect(bypass, "GET", "/user/repo", fn conn ->
      resp(conn, 304, "")
    end)

    expect(bypass, "GET", "/user/repo/commits", fn conn ->
      resp(conn, 500, "")
    end)

    assert {:eol, [], [@project_from_source]} = meta()
    assert log() =~ "Something went wrong (try again later)"
  end

  test "project not modified, skip", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 304, "")
    end)

    assert {:eol, [], []} = meta()
  end

  test "forbidden, skip project", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 403, "")
    end)

    assert {:eol, [], []} = meta()
    assert log() =~ "Forbidden (project skipped)"
  end

  test "rate limit, sleep", %{bypass: bypass} do
    expect(bypass, fn conn ->
      conn
      |> put_resp_header("X-RateLimit-Remaining", "0")
      |> put_resp_header("X-RateLimit-Reset", "1600000000")
      |> resp(403, "")
    end)

    assert {{:sleep, _}, [], [@project_from_source]} = meta()
  end

  test "project deleted or archived", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 404, "")
    end)

    assert {:eol, [%{exist: false}], []} = meta()
    assert log() =~ "Project not found (project deleted)"
  end

  test "error commits parse, try again", %{bypass: bypass} do
    expect(bypass, "GET", "/user/repo", fn conn ->
      resp(conn, 304, "")
    end)

    expect(bypass, "GET", "/user/repo/commits", fn conn ->
      resp(conn, 500, "")
    end)

    assert {:eol, [], [@project_from_source]} = meta()
    assert log() =~ "Something went wrong (try again later)"
  end

  test "invalid meta response, skip project", %{bypass: bypass} do
    expect(bypass, "GET", "/user/repo", fn conn ->
      resp(conn, 200, "wrong response")
    end)

    assert {:eol, [], []} = meta()
    assert log() =~ "Cannot parse stars count, wrong json"
  end

  test "invalid commits response, skip project", %{bypass: bypass} do
    expect(bypass, "GET", "/user/repo", fn conn ->
      resp(conn, 200, @github_api_meta)
    end)

    expect(bypass, "GET", "/user/repo/commits", fn conn ->
      resp(conn, 200, "wrong response")
    end)

    assert {:eol, [], []} = meta()
    assert log() =~ "Cannot parse last commit date, wrong json"
  end

  test "valid meta and commits, to db", %{bypass: bypass} do
    expect(bypass, "GET", "/user/repo", fn conn ->
      resp(conn, 200, @github_api_meta)
    end)

    expect(bypass, "GET", "/user/repo/commits", fn conn ->
      resp(conn, 200, @github_api_commits)
    end)

    assert {:eol, [project_with_meta], []} = meta()
    assert @project_with_meta = to_map(project_with_meta)
  end
end
