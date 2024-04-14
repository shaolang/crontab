defmodule Crontab.DateHelperTest do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Crontab.DateHelper
  alias Crontab.DateHelper

  describe "inc_month/1" do
    test "does not jump over month" do
      assert DateHelper.inc_month(~N[2019-05-31 23:00:00]) == ~N[2019-06-01 23:00:00]
    end
  end

  describe "dec_year/1" do
    test "non-leap year back to leap year at end feb" do
      given = ~N[2025-02-28 00:00:00]
      assert DateHelper.dec_year(given) == ~N[2024-02-28 00:00:00]
    end

    test "leap year back to non-leap year at end feb" do
      given = ~N[2024-02-29 00:00:00]
      assert DateHelper.dec_year(given) == ~N[2023-02-28 00:00:00]
    end

    test "non-leap year back to leap year at start mar" do
      given = ~N[2025-03-01 00:00:00]
      assert DateHelper.dec_year(given) == ~N[2024-03-01 00:00:00]
    end

    test "leap year back to non-leap year at start mar" do
      given = ~N[2024-03-01 00:00:00]
      assert DateHelper.dec_year(given) == ~N[2023-03-01 00:00:00]
    end

    test "non-leap year back to non-leap year" do
      given = ~N[2026-03-01 00:00:00]
      assert DateHelper.dec_year(given) == ~N[2025-03-01 00:00:00]
    end
  end

  describe "inc_year/1" do
    test "non-leap year to leap year at end feb" do
      given = ~N[2023-02-28 00:00:00]
      assert DateHelper.inc_year(given) == ~N[2024-02-28 00:00:00]
    end

    test "leap year to non-leap year at end feb" do
      given = ~N[2024-02-29 00:00:00]
      assert DateHelper.inc_year(given) == ~N[2025-02-28 00:00:00]
    end

    test "non-leap year to leap year at start mar" do
      given = ~N[2023-03-01 00:00:00]
      assert DateHelper.inc_year(given) == ~N[2024-03-01 00:00:00]
    end

    test "leap year to non-leap year at start mar" do
      given = ~N[2024-03-01 00:00:00]
      assert DateHelper.inc_year(given) == ~N[2025-03-01 00:00:00]
    end

    test "non-leap year to non-leap year" do
      given = ~N[2025-03-01 00:00:00]
      assert DateHelper.inc_year(given) == ~N[2026-03-01 00:00:00]
    end
  end

  describe "add/3 on NaiveDateTime" do
    test "one day to day before NY DST starts" do
      date = ~N[2024-03-09 12:34:56]
      assert DateHelper.add(date, 1, :day) == ~N[2024-03-10 12:34:56]
    end
  end

  describe "add/3 on DateTime UTC" do
    test "one day to day before NY DST starts" do
      date = ~U[2024-03-09 12:34:56Z]
      assert DateHelper.add(date, 1, :day) == ~U[2024-03-10 12:34:56Z]
    end
  end

  describe "add/3 on DateTime NYT" do
    test "one day to day before NY DST starts" do
      day_before = DateTime.from_naive!(~N[2024-03-09 12:34:56], "America/New_York")
      expected = DateTime.from_naive!(~N[2024-03-10 12:34:56], "America/New_York")

      assert DateHelper.add(day_before, 1, :day) == expected
    end

    test "one day to day before NY DST ends" do
      day_before = DateTime.from_naive!(~N[2024-11-02 12:34:56], "America/New_York")
      expected = DateTime.from_naive!(~N[2024-11-03 12:34:56], "America/New_York")

      assert DateHelper.add(day_before, 1, :day) == expected
    end

    for {unit, time} <- [{:second, ~T[03:00:00]}, {:minute, ~T[03:00:59]}, {:hour, ~T[03:59:59]}] do
      test "one #{unit} to one second before NY DST starts" do
        one_sec_before = DateTime.from_naive!(~N[2024-03-10 01:59:59], "America/New_York")
        expected = DateTime.new!(~D[2024-03-10], unquote(Macro.escape(time)), "America/New_York")

        assert DateHelper.add(one_sec_before, 1, unquote(unit)) == expected
      end
    end

    for {unit, hour, minute, second} <- [
          {:second, 1, 0, 0},
          {:minute, 1, 0, 59},
          {:hour, 1, 59, 59}
        ] do
      test "one #{unit} to one second before NY DST ends and :on_ambiguity is :later" do
        one_sec_before = DateTime.from_naive!(~N[2024-11-03 00:59:59], "America/New_York")
        new_time = Time.new!(unquote(hour), unquote(minute), unquote(second))
        {:ambiguous, _, expected} = DateTime.new(~D[2024-11-03], new_time, "America/New_York")

        assert DateHelper.add(one_sec_before, 1, unquote(unit), :later) == expected
      end
    end

    for {unit, hour, minute, second, on_ambiguity} <- [
          {:second, 1, 0, 0, :earlier},
          {:minute, 1, 0, 59, :earlier},
          {:hour, 1, 59, 59, :earlier},
          {:second, 1, 0, 0, :both},
          {:minute, 1, 0, 59, :both},
          {:hour, 1, 59, 59, :both}
        ] do
      test "one #{unit} to one second before NY DST ends and :on_ambiguity is #{on_ambiguity}" do
        one_sec_before = DateTime.from_naive!(~N[2024-11-03 00:59:59], "America/New_York")
        new_time = Time.new!(unquote(hour), unquote(minute), unquote(second))
        {:ambiguous, expected, _} = DateTime.new(~D[2024-11-03], new_time, "America/New_York")

        assert DateHelper.add(one_sec_before, 1, unquote(unit), unquote(on_ambiguity)) == expected
      end
    end

    test "on_ambiguity == :later and current time is already non daylight saving + 1 sec" do
      {:ambiguous, _, current_time} =
        DateTime.from_naive(~N[2024-11-03 01:00:00], "America/New_York")

      {:ambiguous, _, expected} = DateTime.from_naive(~N[2024-11-03 01:00:01], "America/New_York")

      assert DateHelper.add(current_time, 1, :second, :later) == expected
    end

    test "on_ambiguity == :later and current time is already non daylight saving + 1 hour" do
      {:ambiguous, _, current_time} =
        DateTime.from_naive(~N[2024-11-03 01:00:00], "America/New_York")

      expected = DateTime.from_naive!(~N[2024-11-03 02:00:00], "America/New_York")

      assert DateHelper.add(current_time, 1, :hour, :later) == expected
    end

    for {expected_utc_offset, on_ambiguity} <- [{-4, :earlier}, {-4, :both}, {-5, :later}] do
      test "on_ambiguity == #{on_ambiguity} and +1 day to 1AM on day before daylight saving ends" do
        one_day_before = DateTime.from_naive!(~N[2024-11-02 01:00:00], "America/New_York")

        %{hour: 1, utc_offset: utc_offset, std_offset: std_offset} =
          DateHelper.add(one_day_before, 1, :day, unquote(on_ambiguity))

        assert utc_offset + std_offset == unquote(expected_utc_offset) * 3600
      end
    end
  end
end
