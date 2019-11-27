defmodule ElixirAwesome.Projects.Helpers do
  @moduledoc false

  @week %{
    1 => "Mon",
    2 => "Tue",
    3 => "Wed",
    4 => "Thu",
    5 => "Fri",
    6 => "Sat",
    7 => "Sun"
  }

  @monthes %{
    1 => "Jan",
    2 => "Feb",
    3 => "Mar",
    4 => "Apr",
    5 => "May",
    6 => "June",
    7 => "Jul",
    8 => "Aug",
    9 => "Sep",
    10 => "Oct",
    11 => "Nov",
    12 => "Dec"
  }

  def get_header(headers, key) do
    import Enum, only: [find: 2]

    func = fn {k, _} -> k == key end

    case find(headers, func) do
      {_, value} -> value
      _ -> nil
    end
  end

  def set_headers(headers) do
    import Base, only: [encode64: 1]
    import Application, only: [get_env: 2]

    github_login = get_env(:elixir_awesome, :github_login)
    github_pass = get_env(:elixir_awesome, :github_pass)

    authorization =
      if github_login && github_pass do
        basic = encode64("#{github_login}:#{github_pass}")

        [{"Authorization", "Basic #{basic}"}]
      else
        []
      end

    authorization ++ (headers || [])
  end

  defp pad(int) do
    import String, only: [pad_leading: 3]

    to_string(int)
    |> pad_leading(2, "0")
  end

  def now_http do
    import DateTime, only: [utc_now: 0]
    import Date, only: [utc_today: 0, day_of_week: 1]

    wd = utc_today() |> day_of_week()

    %{
      year: y,
      month: m,
      day: d,
      hour: h,
      minute: min,
      second: sec
    } = utc_now()

    "#{@week[wd]}, #{pad(d)} #{@monthes[m]} #{pad(y)}" <>
      " #{pad(h)}:#{pad(min)}:#{pad(sec)} GMT"
  end
end
