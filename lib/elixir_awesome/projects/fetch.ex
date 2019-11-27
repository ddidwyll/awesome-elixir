defmodule ElixirAwesome.Projects.Fetch do
  @moduledoc """
  fetch and parse markdown file with list of awesome
  elixir projects by category, with github repo url
  and shot description
  """

  import Logger, only: [debug: 1, warn: 1]
  import HtmlSanitizeEx, only: [strip_tags: 1]

  defp fetch_list(header) do
    import ElixirAwesome.Projects.Helpers
    import Application, only: [get_env: 2]
    import HTTPoison, only: [get: 2]
    alias HTTPoison.Response, as: R
    alias HTTPoison.Error, as: E

    source_url = get_env(:elixir_awesome, :parse_url)

    debug("Try to fetch source from #{source_url}")

    case get(source_url, set_headers(header)) do
      {:ok, %R{status_code: 304}} ->
        debug("Source file not modified, skip")
        :skip

      {:ok, %R{status_code: 200, body: body, headers: headers}} ->
        etag = get_header(headers, "ETag")
        debug("Source file fetched successful")
        {:ok, body, etag}

      {:ok, %R{status_code: 404}} ->
        warn("Source file not exist, check url")
        {:error, "Not found"}

      {:error, %E{reason: reason}} ->
        warn("Fetch error, #{reason}")
        {:error, reason}

      _ ->
        warn("Fetch error")
        {:error, "Someting went wrong"}
    end
  end

  defp check_source(file) do
    import String, only: [split: 2]

    with true <- is_binary(file),
         lines <- split(file, ~r{\r\n?|\n}),
         true <- length(lines) > 1 do
      debug("Source file checked successful")
      {:ok, lines}
    else
      _ ->
        warn("Source file has wrong format")
        {:error, "Wrong source file"}
    end
  end

  defp parse_markdown(lines) do
    import Earmark.Parser, only: [parse: 1]
    import Enum, only: [drop: 2]

    {blocks, _, _} = parse(lines)
    content = drop(blocks, 5)

    if length(content) > 1 do
      debug("Source file checked successful")
      {:ok, content}
    else
      warn("Source file too short")
      {:error, "Source too short"}
    end
  end

  defp to_html(md) do
    import Earmark, only: [as_html: 1]
    import HtmlSanitizeEx, only: [markdown_html: 1]

    case as_html(md) do
      {:ok, html, _} -> markdown_html(html)
      _ -> warn("Wrong markdown format: #{md}") && ""
    end
  end

  defp parse_project(cat, line) do
    import String, only: [split: 3]
    import Regex, only: [run: 2]

    [left, right] = split(line, " - ", parts: 2)
    [_, name, url] = run(~r/\[(.+)\]\((.+)\)/, left)

    %{
      url: url,
      name: strip_tags(name),
      description: to_html(right),
      category_name: cat.name,
      exist: true
    }
  end

  defp parse_blocks([]) do
    debug("Not enough blocks")
    {:error, "Blocks empty"}
  end

  defp parse_blocks(blocks) do
    debug("Start parsing blocks")
    parse_blocks(blocks, [], [])
  end

  defp parse_blocks([], cats, projects) do
    debug("End of blocks, parsed successful")
    {:ok, cats, projects}
  end

  defp parse_blocks([block | blocks], cats, projects) do
    import List, only: [first: 1]
    alias Earmark.Block.Heading, as: H
    alias Earmark.Block.Para, as: P
    alias Earmark.Block.List, as: L
    alias Earmark.Block.ListItem, as: I

    case block do
      %H{level: 2, content: name} ->
        cat = %{
          name: strip_tags(name),
          description: nil,
          exist: true
        }

        parse_blocks(blocks, [cat | cats], projects)

      %P{lines: [line | _]} ->
        [last_cat | cats_tail] = cats
        cat = %{last_cat | description: to_html(line)}
        parse_blocks(blocks, [cat | cats_tail], projects)

      %L{blocks: list} ->
        current_projects =
          for list_item <- list do
            %I{
              blocks: [%P{lines: [line | _]} | _]
            } = list_item

            (first(cats) || %{name: "N\A"})
            |> parse_project(line)
          end

        parse_blocks(blocks, cats, current_projects ++ projects)

      %H{level: 1} ->
        debug("End of blocks, parsed successful")
        {:ok, cats, projects}

      unexpected_block ->
        warn("Unexpected block #{inspect(unexpected_block)}")
        parse_blocks(blocks, cats, projects)
    end
  end

  def fetch(header) do
    with {:ok, file, etag} <- fetch_list(header),
         {:ok, lines} <- check_source(file),
         {:ok, blocks} <- parse_markdown(lines),
         {:ok, cats, projects} <- parse_blocks(blocks) do
      {:ok, cats, projects, etag || ""}
    else
      {:error, error} -> {:error, error}
      :skip -> :skip
    end
  end
end
