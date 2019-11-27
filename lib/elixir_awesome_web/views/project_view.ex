defmodule ElixirAwesomeWeb.ProjectView do
  use ElixirAwesomeWeb, :view

  def highlight(string, nil), do: string

  def highlight(string, re) do
    import Regex, only: [replace: 3]

    replace(re, string, "<b><em>\\0</em></b>")
  end

  def days_ago(datetime) do
    import NaiveDateTime, only: [utc_now: 0, diff: 2]
    import Integer, only: [floor_div: 2]

    days_ago =
      diff(utc_now(), datetime)
      |> floor_div(86400)

    case days_ago do
      0 -> "today"
      1 -> "yesterday"
      _ -> "#{days_ago}d ago"
    end
  end
end
