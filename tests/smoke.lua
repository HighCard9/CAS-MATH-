--[[
  Desktop smoke tests for calc2 modules (standard Lua 5.x).
  Run from repo root: lua tests/smoke.lua
]]

local INF = "\u{221E}"

package.path = "src/?.lua;" .. package.path

local core = require("calc2.core")
local sequences = require("calc2.sequences")
local series_basics = require("calc2.series_basics")
local series_tests = require("calc2.series_tests")

--- Minimal CAS stub: extend this table as more tests need exact CAS strings.
local function make_mock_eval()
  local exact = {
    ["substitute(n^2, n, 4)"] = "16",
    ["limit(1/n, n, " .. INF .. ")"] = "0",
    ["limit(5, n, " .. INF .. ")"] = "5",
    ["sum(n, n, 1, 5)"] = "15",
    ["sum((1/2)^n, n, 1, 3)"] = "7/8",
    ["sum((1/2)^n, n, 1, " .. INF .. ")"] = "1",
    ["1/(1-(0.5))"] = "2",
    ["when(0 < 1, \"abs_conv\", \"_\")"] = "abs_conv",
    ["when(1 < 1, \"abs_conv\", \"_\")"] = "_",
    ["when(1 > 1, \"div\", \"_\")"] = "_",
    ["when(1 = 1, \"inc\", \"_\")"] = "inc",
    ["when(0 = 0, \"zero\", \"nonzero\")"] = "zero",
    ["when(5 = 0, \"zero\", \"nonzero\")"] = "nonzero",
    ["limit((abs(1/n^2))^(1/n), n, " .. INF .. ")"] = "1",
  }
  exact["limit(abs(substitute(1/n^2, n, n+1)/(1/n^2)), n, " .. INF .. ")"] = "1"

  return function(expr)
    local s = exact[expr]
    if s ~= nil then
      return s, nil
    end
    return nil, "mock_unimplemented:" .. tostring(expr)
  end
end

local ctx = { evalStr = make_mock_eval() }

local nfail = 0
local function assert_eq(a, b, msg)
  if a ~= b then
    io.stderr:write(string.format("FAIL: %s (got %q expected %q)\n", msg, a, b))
    nfail = nfail + 1
  end
end

local function assert_true(cond, msg)
  if not cond then
    io.stderr:write("FAIL: " .. msg .. "\n")
    nfail = nfail + 1
  end
end

-- core: no CAS
do
  core.clear_steps()
  core.step("A", "one")
  core.step("B", "two")
  local steps = core.get_steps()
  assert_eq(#steps, 2, "step count")
  assert_eq(steps[1].title, "A", "step title")
  local ok, err = pcall(function()
    core.assert_positive_int(0, "k")
  end)
  assert_true(not ok, "assert_positive_int rejects 0")
  assert_true(core.near(1, 1 + 1e-12), "near")
end

-- cas_eval without mock
do
  local ok = core.cas_eval("1+1", {})
  if type(math) == "table" and type(math.evalStr) == "function" then
    -- on device this might run; in CI typically no math.evalStr
  else
    assert_true(not ok, "cas_eval fails without evalStr")
  end
end

-- sequences + series with mock
do
  local ok, v, err = sequences.sequence_term("n^2", 4, ctx)
  assert_true(ok, "sequence_term ok")
  assert_eq(v, "16", "sequence_term value")

  ok, v, err = sequences.limit_sequence("1/n", ctx)
  assert_true(ok, "limit_sequence ok")
  assert_eq(v, "0", "limit_sequence value")
end

do
  local ok, v, err = series_basics.partial_sum("n", 5, ctx)
  assert_true(ok, "partial_sum ok")
  assert_eq(v, "15", "partial_sum value")

  ok, v, err = series_basics.infinite_sum_if_converges("(1/2)^n", ctx)
  assert_true(ok, "infinite_sum ok")
  assert_eq(v, "1", "infinite_sum value")
end

do
  local ok, summary, err = series_basics.geometric_series(1, 0.5, ctx)
  assert_true(ok, "geometric_series ok")
  assert_true(summary.converges, "geometric converges")
  assert_eq(summary.sum_value, "2", "geometric sum")
end

do
  local ok, res, err = series_tests.geometric_test_ratio(0.5, ctx)
  assert_true(ok, "geometric_test_ratio")
  assert_true(res.converges, "geom ratio conv")
end

do
  local ok, res, err = series_tests.p_series_classify(2, ctx)
  assert_true(ok, "p_series")
  assert_true(res.converges, "p>1")
end

do
  local ok, res, err = series_tests.nth_term_test("1/n", ctx)
  assert_true(ok, "nth_term inconclusive")
  assert_eq(res.verdict, "inconclusive", "nth 1/n")

  ok, res, err = series_tests.nth_term_test("5", ctx)
  assert_true(ok, "nth_term diverges")
  assert_eq(res.verdict, "diverges", "nth const")
end

do
  local ok, res, err = series_tests.ratio_test("1/n^2", ctx)
  assert_true(ok, "ratio_test")
  assert_eq(res.verdict, "inconclusive", "ratio p-series")
end

do
  local ok, res, err = series_tests.root_test("1/n^2", ctx)
  assert_true(ok, "root_test")
  assert_eq(res.verdict, "inconclusive", "root p-series")
end

if nfail > 0 then
  os.exit(1)
end
print("smoke: ok")
