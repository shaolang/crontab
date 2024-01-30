defmodule Crontab.DateHelper do
  @moduledoc false
  alias Crontab.DateChecker

  @type unit :: :year | :month | :day | :hour | :minute | :second | :microsecond

  @units [
    {:year, {nil, nil}},
    {:month, {1, 12}},
    {:day, {1, :end_onf_month}},
    {:hour, {0, 23}},
    {:minute, {0, 59}},
    {:second, {0, 59}},
    {:microsecond, {{0, 0}, {999_999, 6}}}
  ]

  @doc """
  Get Start of a period of a date.

  ## Examples

      iex> Crontab.DateHelper.beginning_of(~N[2016-03-14 01:45:45.123], :year)
      ~N[2016-01-01 00:00:00]

      iex> Crontab.DateHelper.beginning_of(~U[2016-03-14T01:45:45.123Z], :year)
      ~U[2016-01-01T00:00:00Z]

  """
  @spec beginning_of(DateChecker.date(), unit) :: DateChecker.date()
  def beginning_of(date, unit) do
    _beginning_of(date, proceeding_units(unit))
  end

  @doc """
  Get the end of a period of a date.

  ## Examples

      iex> Crontab.DateHelper.end_of(~N[2016-03-14 01:45:45.123], :year)
      ~N[2016-12-31 23:59:59.999999]

      iex> Crontab.DateHelper.end_of(~U[2016-03-14T01:45:45.123Z], :year)
      ~U[2016-12-31 23:59:59.999999Z]
  """
  @spec end_of(DateChecker.date(), unit) :: DateChecker.date()
  def end_of(date, unit) do
    _end_of(date, proceeding_units(unit))
  end

  @doc """
  Find the last occurrence of weekday in month.
  """
  @spec last_weekday(DateChecker.date(), Calendar.day_of_week()) :: Calendar.day()
  def last_weekday(date, weekday) do
    date
    |> end_of(:month)
    |> last_weekday(weekday, :end)
  end

  @doc """
  Find the nth weekday of month.
  """
  @spec nth_weekday(DateChecker.date(), Calendar.day_of_week(), integer) :: Calendar.day()
  def nth_weekday(date, weekday, n) do
    date
    |> beginning_of(:month)
    |> nth_weekday(weekday, n, :start)
  end

  @doc """
  Find the last occurrence of weekday in month.
  """
  @spec last_weekday_of_month(DateChecker.date()) :: Calendar.day()
  def last_weekday_of_month(date) do
    last_weekday_of_month(end_of(date, :month), :end)
  end

  @doc """
  Find the next occurrence of weekday relative to date.
  """
  @spec next_weekday_to(DateChecker.date()) :: Calendar.day()
  def next_weekday_to(date = %{year: year, month: month, day: day}) do
    weekday = :calendar.day_of_the_week(year, month, day)
    next_day = mod(date).add(date, 86_400, :second)
    previous_day = mod(date).add(date, -86_400, :second)

    cond do
      weekday == 7 && next_day.month == date.month -> next_day.day
      weekday == 7 -> mod(date).add(date, -86_400 * 2, :second).day
      weekday == 6 && previous_day.month == date.month -> previous_day.day
      weekday == 6 -> mod(date).add(date, 86_400 * 2, :second).day
      true -> date.day
    end
  end

  @spec inc_year(DateChecker.date()) :: DateChecker.date()
  def inc_year(date) do
    leap_year? =
      date
      |> mod(date).to_date()
      |> Date.leap_year?()

    if leap_year? do
      mod(date).add(date, 366 * 86_400, :second)
    else
      mod(date).add(date, 365 * 86_400, :second)
    end
  end

  @spec dec_year(DateChecker.date()) :: DateChecker.date()
  def dec_year(date) do
    leap_year? =
      date
      |> mod(date).to_date()
      |> Date.leap_year?()

    if leap_year? do
      mod(date).add(date, -366 * 86_400, :second)
    else
      mod(date).add(date, -365 * 86_400, :second)
    end
  end

  @spec inc_month(DateChecker.date()) :: DateChecker.date()
  def inc_month(date = %{day: day}) do
    days =
      date
      |> mod(date).to_date()
      |> Date.days_in_month()

    mod(date).add(date, (days + 1 - day) * 86_400, :second)
  end

  @spec dec_month(DateChecker.date()) :: DateChecker.date()
  def dec_month(date) do
    days =
      date
      |> mod(date).to_date()
      |> Date.days_in_month()

    mod(date).add(date, days * -86_400, :second)
  end

  @doc """
  Get the Nth day before the last day of the month.

  ## Examples

      iex> Crontab.DateHelper.nth_day_before_month_end(~N[2016-03-14 01:45:45.123], 5)
      ~N[2016-03-26 01:45:45.123]

  """
  @spec nth_day_before_month_end(date :: DateChecker.date(), days_before :: pos_integer()) ::
          DateChecker.date()
  def nth_day_before_month_end(datetime, days_before) do
    mod = mod(datetime)

    datetime
    |> end_of(:month)
    |> mod.add(-days_before, :day)
    |> mod.to_date()
    |> mod.new!(mod.to_time(datetime))
  end

  @spec _beginning_of(DateChecker.date(), [{unit, {any, any}}]) :: DateChecker.date()
  defp _beginning_of(date, [{unit, {lower, _}} | tail]) do
    _beginning_of(Map.put(date, unit, lower), tail)
  end

  defp _beginning_of(date, []), do: date

  @spec _end_of(DateChecker.date(), [{unit, {any, any}}]) :: DateChecker.date()
  defp _end_of(date, [{unit, {_, :end_onf_month}} | tail]) do
    upper =
      date
      |> mod(date).to_date()
      |> Date.days_in_month()

    _end_of(Map.put(date, unit, upper), tail)
  end

  defp _end_of(date, [{unit, {_, upper}} | tail]) do
    _end_of(Map.put(date, unit, upper), tail)
  end

  defp _end_of(date, []), do: date

  @spec proceeding_units(unit) :: [{unit, {any, any}}]
  defp proceeding_units(unit) do
    [_ | units] =
      @units
      |> Enum.reduce([], fn {key, value}, acc ->
        cond do
          Enum.count(acc) > 0 ->
            Enum.concat(acc, [{key, value}])

          key == unit ->
            [{key, value}]

          true ->
            []
        end
      end)

    units
  end

  @spec nth_weekday(DateChecker.date(), Calendar.day_of_week(), :start) :: boolean
  defp nth_weekday(date, _, 0, :start),
    do: mod(date).add(date, -86_400, :second).day

  defp nth_weekday(date = %{year: year, month: month, day: day}, weekday, n, :start) do
    if :calendar.day_of_the_week(year, month, day) == weekday do
      nth_weekday(mod(date).add(date, 86_400, :second), weekday, n - 1, :start)
    else
      nth_weekday(mod(date).add(date, 86_400, :second), weekday, n, :start)
    end
  end

  @spec last_weekday_of_month(DateChecker.date(), :end) :: Calendar.day()
  defp last_weekday_of_month(date = %{year: year, month: month, day: day}, :end) do
    weekday = :calendar.day_of_the_week(year, month, day)

    if weekday > 5 do
      last_weekday_of_month(mod(date).add(date, -86_400, :second), :end)
    else
      day
    end
  end

  @spec last_weekday(DateChecker.date(), non_neg_integer, :end) :: Calendar.day()
  defp last_weekday(date = %{year: year, month: month, day: day}, weekday, :end) do
    if :calendar.day_of_the_week(year, month, day) == weekday do
      day
    else
      last_weekday(mod(date).add(date, -86_400, :second), weekday, :end)
    end
  end

  defp mod(%DateTime{}), do: DateTime
  defp mod(%NaiveDateTime{}), do: NaiveDateTime
end
