defmodule ElixirAwesome.Projects.Crawler do
  @moduledoc false

  use GenServer

  alias ElixirAwesome.Repo
  alias ElixirAwesome.Projects
  alias ElixirAwesome.Projects.Meta
  alias ElixirAwesome.Projects.Fetch
  alias ElixirAwesome.Projects.Helpers

  @day_sec 86400
  @fetch_replace [
    :name,
    :description,
    :exist
  ]

  def start_link(_) do
    import GenServer, only: [start_link: 3]
    import Application, only: [get_env: 2]
    import :dets, only: [open_file: 2]
    import String, only: [to_atom: 1]

    file = get_env(:elixir_awesome, :mod_times_file) |> to_atom
    open_file(:mod_times, type: :set, file: file)

    start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    state = %{
      projects_queue: [],
      fetch_delay: 1,
      meta_delay: 1,
      meta_job: nil
    }

    cast(:fetch, 30)
    {:ok, state}
  end

  defp cast(msg, after_sec \\ 1) do
    import Process, only: [send_after: 3]

    send_after(__MODULE__, msg, after_sec * 1000)
  end

  defp updated(fetched \\ nil) do
    import :dets, only: [insert: 2, sync: 1]
    import Helpers, only: [now_http: 0]

    case fetched do
      {projects, etag} ->
        insert(
          :mod_times,
          {:fetch, {projects, [{"If-None-Match", etag}]}}
        )

      nil ->
        insert(
          :mod_times,
          {:meta, [{"If-Modified-Since", now_http()}]}
        )
    end

    sync(:mod_times)
  end

  def last_update(what) do
    import :dets, only: [lookup: 2]

    lookup(:mod_times, what)[what]
  end

  @impl true
  def handle_info(:meta, state) do
    import Process, only: [cancel_timer: 1]
    import Meta
    import Projects
    import Repo

    if state.meta_job, do: cancel_timer(state.meta_job)

    {status, to_db, try_again} =
      meta({state.projects_queue, last_update(:meta)})

    if length(to_db) > 0 do
      query()
      |> upsert_projects(to_db)
      |> transaction()
    end

    {sleep, delay} =
      case status do
        {:sleep, sec} -> {sec + 10, 1}
        _ -> {state.meta_delay, state.meta_delay * 2}
      end

    if length(try_again) > 0 do
      {:noreply,
       %{
         state
         | projects_queue: try_again,
           meta_job: cast(:meta, sleep),
           meta_delay: delay
       }}
    else
      updated()
      {:noreply, %{state | projects_queue: [], meta_delay: 1}}
    end
  end

  @impl true
  def handle_info(:fetch, state) do
    import Fetch
    import Projects
    import Repo

    with {_, header} <- last_update(:fetch) || {nil, nil},
         {:ok, cats, projects, etag} <- fetch(header),
         {:ok, %{ups_p: {_, projects}}} <-
           query()
           |> invalidate_all()
           |> upsert_categories(cats)
           |> upsert_projects(projects, @fetch_replace)
           |> transaction() do
      updated({projects, etag})
      cast(:fetch, @day_sec)
      cast(:meta)

      {:noreply,
       %{
         state
         | projects_queue: projects,
           fetch_delay: 1
       }}
    else
      :skip ->
        {last_queue, _} = last_update(:fetch) || {[], nil}
        cast(:fetch, @day_sec)
        cast(:meta)

        {:noreply,
         %{
           state
           | fetch_delay: 1,
             projects_queue: last_queue
         }}

      _ ->
        delay = state.fetch_delay * 2
        cast(:fetch, delay)
        {:noreply, %{state | fetch_delay: delay}}
    end
  end

  def go, do: cast(:fetch, 0)
end
