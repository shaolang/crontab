defmodule Crontab.DateHelperTest do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Crontab.DateHelper

  describe "inc_month/1" do
    test "does not jump obver month" do
      assert Crontab.DateHelper.inc_month(~N[2019-05-31 23:00:00]) == ~N[2019-06-01 23:00:00]
    end
  end

  describe "beginning_of/2" do
    test_cases = [
      {~N[2024-01-31 01:23:45], ~N[2024-01-01 00:00:00], :month},
      {~N[2024-02-29 12:34:56], ~N[2024-02-01 00:00:00], :month},
      {~U[2024-01-31T01:23:45Z], ~U[2024-01-01T00:00:00Z], :month},
      {~U[2024-02-21T12:34:56Z], ~U[2024-02-01T00:00:00Z], :month}
    ]

    for {now, expected, unit} = neu <- test_cases do
      test "returns #{expected} as beginning of #{unit} when given #{now}" do
        {now, expected, unit} = unquote(Macro.escape(neu))

        assert Crontab.DateHelper.beginning_of(now, unit) == expected
      end
    end
  end

  describe "end_of/2" do
    test_cases = [
      {~N[2024-01-01 01:23:45], ~N[2024-01-31 23:59:59.999999], :month},
      {~N[2024-02-01 12:34:56], ~N[2024-02-29 23:59:59.999999], :month},
      {~U[2024-01-01T01:23:45Z], ~U[2024-01-31T23:59:59.999999Z], :month},
      {~U[2024-02-01T12:34:56Z], ~U[2024-02-29T23:59:59.999999Z], :month}
    ]

    for {now, expected, unit} = neu <- test_cases do
      test "returns #{expected} as end of #{unit} when given #{now}" do
        {now, expected, unit} = unquote(Macro.escape(neu))

        assert Crontab.DateHelper.end_of(now, unit) == expected
      end
    end
  end

  describe "nth_day_before_month_end/2" do
    test_cases = [
      {~N[2024-01-01 01:23:45], 1, ~N[2024-01-30 01:23:45]},
      {~N[2024-01-01 12:34:56], 6, ~N[2024-01-25 12:34:56]},
      {~U[2024-01-01T01:23:45Z], 1, ~U[2024-01-30T01:23:45Z]},
      {~U[2024-01-01T12:34:56Z], 6, ~U[2024-01-25T12:34:56Z]}
    ]

    for {now, days_ago, expected} = nde <- test_cases do
      test "returns #{expected} as #{days_ago} days before last day of month of #{now}" do
        {now, days_ago, expected} = unquote(Macro.escape(nde))

        assert Crontab.DateHelper.nth_day_before_month_end(now, days_ago) == expected
      end
    end
  end
end
