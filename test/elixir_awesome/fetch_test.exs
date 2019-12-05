defmodule ElixirAwesome.Projects.FetchTest do
  use ExUnit.Case
  use ElixirAwesomeStubs

  import Bypass, only: [open: 0, expect: 2, down: 1]
  import Application, only: [put_env: 3]
  import Plug.Conn, only: [resp: 3]
  import ElixirAwesome.Projects.Fetch
  import ExUnit.CaptureLog

  setup do
    bypass = open()
    mock_url = "http://localhost:#{bypass.port}"
    put_env(:elixir_awesome, :parse_url, mock_url)

    {:ok, bypass: bypass}
  end

  test "no connection", %{bypass: bypass} do
    down(bypass)

    assert {:error, :econnrefused} = fetch(nil)
  end

  test "server error", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 500, "")
    end)

    assert {:error, "Someting went wrong"} = fetch(nil)
  end

  test "source file not found", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 404, "")
    end)

    assert {:error, "Source file not found"} = fetch(nil)
  end

  test "source file not modified", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 304, "")
    end)

    assert :skip = fetch(nil)
  end

  test "source file with wrong format", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 200, @source_empty)
    end)

    assert {:error, "Wrong source file"} = fetch(nil)
  end

  # data specs https://github.com/h4cc/awesome-elixir/tree/master/tests
  test "source file without data", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 200, @source_one_block)
    end)

    assert {:error, "Source too short"} = fetch(nil)
  end

  test "source file with wrong struct", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 200, @source_no_cat)
    end)

    assert {:error, "Wrong source file struct"} = fetch(nil)
  end

  test "source with one cat and description", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 200, @source_cat)
    end)

    assert {:ok, [@cat_from_source], [], _} = fetch(nil)
  end

  test "source with one incorrect project", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 200, @source_project_invalid)
    end)

    assert {:ok, [@cat_from_source], [], _} = fetch(nil)
  end

  test "source with one correct project", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(conn, 200, @source_project_valid <> @fragment_skipped)
    end)

    assert {:ok, [@cat_from_source], [@project_from_source], _} =
             fetch(nil)
  end

  test "source with unexpected block", %{bypass: bypass} do
    expect(bypass, fn conn ->
      resp(
        conn,
        200,
        @source_project_valid <> @fragment_unexpected_quote
      )
    end)

    assert capture_log(fn -> fetch(nil) end) =~
             "Unexpected block %Earmark.Block.BlockQuote"
  end
end
