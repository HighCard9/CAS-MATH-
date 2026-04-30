--[[
  CAS-MATH — Calc 2 helpers + CAS smoke in ONE file for TI-Nspire CX CAS.

  HOW TO BUILD .tns
  1. New document → insert a Lua script page (Script Editor / Lua).
  2. Select all default script text, delete it, paste this entire file.
  3. Save the document; Student Software / OS saves as .tns.

  CAS calls run only in on.paint (math.evalStr is not valid during script init).

  UTF-8 infinity for Lua 5.1 on Nspire:
]]
local INF = "\226\136\158"

-- ========== calc2.core (inlined) ==========
local core = {}
local step_buffer = {}

function core.clear_steps()
  step_buffer = {}
end

function core.step(title, body)
  local s = { title = title or "", body = body or "" }
  step_buffer[#step_buffer + 1] = s
  return s
end

function core.get_steps()
  return step_buffer
end

function core.tolerance()
  return 1e-9
end

function core.near(a, b)
  local t = core.tolerance()
  return math.abs(a - b) <= t * (1 + math.max(math.abs(a), math.abs(b)))
end

function core.assert_positive_int(n, name)
  name = name or "n"
  if type(n) ~= "number" or n ~= math.floor(n) or n < 1 then
    error(name .. " must be a positive integer")
  end
end

function core.cas_eval(expr, ctx)
  ctx = ctx or {}
  local evalStr = ctx.evalStr
  if not evalStr and type(math) == "table" and type(math.evalStr) == "function" then
    evalStr = math.evalStr
  end
  if type(evalStr) ~= "function" then
    return false, nil, "cas_unavailable"
  end
  local a, b = evalStr(expr)
  if a == nil then
    return false, nil, b or "eval_failed"
  end
  return true, tostring(a), nil
end

function core.format_expr(expr)
  return tostring(expr or "")
end

-- ========== calc2.sequences (inlined) ==========
local sequences = {}

function sequences.sequence_term(a_n, k, ctx)
  core.assert_positive_int(k, "k")
  local expr = string.format("substitute(%s, n, %d)", a_n, k)
  return core.cas_eval(expr, ctx)
end

function sequences.limit_sequence(a_n, ctx)
  local expr = string.format("limit(%s, n, %s)", a_n, INF)
  return core.cas_eval(expr, ctx)
end

-- ========== calc2.series_basics (inlined) ==========
local series_basics = {}

function series_basics.partial_sum(a_n, k, ctx)
  core.assert_positive_int(k, "k")
  local expr = string.format("sum(%s, n, 1, %d)", a_n, k)
  return core.cas_eval(expr, ctx)
end

function series_basics.infinite_sum_if_converges(a_n, ctx)
  local expr = string.format("sum(%s, n, 1, %s)", a_n, INF)
  return core.cas_eval(expr, ctx)
end

function series_basics.geometric_series(a, r, ctx)
  core.clear_steps()
  local astr = type(a) == "number" and tostring(a) or "(" .. tostring(a) .. ")"
  local rstr = type(r) == "number" and tostring(r) or "(" .. tostring(r) .. ")"

  core.step("Series", string.format("sum (0..inf) (%s)(%s)^n", astr, rstr))

  if type(r) == "number" then
    local ar = math.abs(r)
    core.step("|r|", string.format("|r| = %g", ar))
    if ar < 1 then
      local sum = astr .. "/(1-(" .. rstr .. "))"
      core.step("Convergence", "|r| < 1: converges.")
      core.step("Sum", "S = " .. sum)
      local ok, val, err = core.cas_eval(sum, ctx)
      return ok, { converges = true, sum_expr = sum, sum_value = val, steps = core.get_steps() }, err
    else
      core.step("Convergence", "|r| >= 1: diverges.")
      return true, { converges = false, sum_expr = nil, sum_value = nil, steps = core.get_steps() }, nil
    end
  end

  local ok_cmp, cmp, err = core.cas_eval(string.format("when(abs(%s)<1, 1, 0)", rstr), ctx)
  if ok_cmp and cmp == "1" then
    local sum = astr .. "/(1-(" .. rstr .. "))"
    core.step("Convergence", "CAS: |r| < 1.")
    core.step("Sum", "S = " .. sum)
    local ok2, val, err2 = core.cas_eval(sum, ctx)
    return ok2, { converges = true, sum_expr = sum, sum_value = val, steps = core.get_steps() }, err2
  end
  if ok_cmp and cmp == "0" then
    core.step("Convergence", "CAS: |r| >= 1.")
    return true, { converges = false, sum_expr = nil, sum_value = nil, steps = core.get_steps() }, nil
  end

  core.step("Convergence", "Could not classify |r|.")
  return false, { converges = nil, sum_expr = nil, sum_value = nil, steps = core.get_steps() }, err or "symbolic_r_failed"
end

-- ========== calc2.series_tests (inlined) ==========
local series_tests = {}

function series_tests.geometric_test_ratio(r, ctx)
  core.clear_steps()
  local rstr = type(r) == "number" and tostring(r) or "(" .. tostring(r) .. ")"
  core.step("Series", "geometric ratio r")
  if type(r) == "number" then
    local ar = math.abs(r)
    core.step("|r|", string.format("%g", ar))
    if ar < 1 then
      core.step("Conclusion", "converges")
      return true, { converges = true, reason = "|r|<1" }, nil
    else
      core.step("Conclusion", "diverges")
      return true, { converges = false, reason = "|r|>=1" }, nil
    end
  end
  local ok, s, err = core.cas_eval(string.format("when(abs(%s)<1, \"conv\", \"div\")", rstr), ctx)
  if not ok then
    return false, nil, err
  end
  if s == "conv" then
    return true, { converges = true, reason = "cas" }, nil
  end
  if s == "div" then
    return true, { converges = false, reason = "cas" }, nil
  end
  return true, { converges = nil, reason = "unknown" }, nil
end

function series_tests.p_series_classify(p, ctx)
  core.clear_steps()
  core.step("Series", "p-series 1/n^p")
  if type(p) == "number" then
    if p > 1 then
      return true, { converges = true }, nil
    else
      return true, { converges = false }, nil
    end
  end
  local pstr = "(" .. tostring(p) .. ")"
  local ok, s, err = core.cas_eval(string.format("when(%s>1, \"conv\", \"div\")", pstr), ctx)
  if not ok then
    return false, nil, err
  end
  if s == "conv" then
    return true, { converges = true }, nil
  end
  if s == "div" then
    return true, { converges = false }, nil
  end
  return true, { converges = nil }, nil
end

function series_tests.nth_term_test(a_n, ctx)
  core.clear_steps()
  local lim_expr = string.format("limit(%s, n, %s)", a_n, INF)
  local ok, lim, err = core.cas_eval(lim_expr, ctx)
  if not ok then
    return false, nil, err
  end
  core.step("Limit", lim)
  local okz, isz, errz = core.cas_eval(string.format("when(%s = 0, \"zero\", \"nonzero\")", lim), ctx)
  if okz and isz == "nonzero" then
    return true, { verdict = "diverges", limit = lim }, nil
  end
  if okz and isz == "zero" then
    return true, { verdict = "inconclusive", limit = lim }, nil
  end
  return true, { verdict = "unknown", limit = lim }, errz
end

function series_tests.ratio_test(a_n, ctx)
  core.clear_steps()
  local ratio = string.format("abs(substitute(%s, n, n+1)/(%s))", a_n, a_n)
  local lim_expr = string.format("limit(%s, n, %s)", ratio, INF)
  local ok, lim, err = core.cas_eval(lim_expr, ctx)
  if not ok then
    return false, nil, err
  end
  local oklt, lt1 = core.cas_eval(string.format("when(%s < 1, \"abs_conv\", \"_\")", lim), ctx)
  if oklt and lt1 == "abs_conv" then
    return true, { verdict = "absolute_convergence", L = lim }, nil
  end
  local okgt, gt1 = core.cas_eval(string.format("when(%s > 1, \"div\", \"_\")", lim), ctx)
  if okgt and gt1 == "div" then
    return true, { verdict = "diverges", L = lim }, nil
  end
  local okeq, eq1 = core.cas_eval(string.format("when(%s = 1, \"inc\", \"_\")", lim), ctx)
  if okeq and eq1 == "inc" then
    return true, { verdict = "inconclusive", L = lim }, nil
  end
  return true, { verdict = "unknown", L = lim }, nil
end

function series_tests.root_test(a_n, ctx)
  core.clear_steps()
  local expr = string.format("limit((abs(%s))^(1/n), n, %s)", a_n, INF)
  local ok, lim, err = core.cas_eval(expr, ctx)
  if not ok then
    return false, nil, err
  end
  local oklt, lt1 = core.cas_eval(string.format("when(%s < 1, \"abs_conv\", \"_\")", lim), ctx)
  if oklt and lt1 == "abs_conv" then
    return true, { verdict = "absolute_convergence", L = lim }, nil
  end
  local okgt, gt1 = core.cas_eval(string.format("when(%s > 1, \"div\", \"_\")", lim), ctx)
  if okgt and gt1 == "div" then
    return true, { verdict = "diverges", L = lim }, nil
  end
  local okeq, eq1 = core.cas_eval(string.format("when(%s = 1, \"inc\", \"_\")", lim), ctx)
  if okeq and eq1 == "inc" then
    return true, { verdict = "inconclusive", L = lim }, nil
  end
  return true, { verdict = "unknown", L = lim }, nil
end

-- ========== Nspire page: CAS smoke + API lines ==========
local display_lines = nil

local function eval_line(label, expr)
  local s, err = math.evalStr(expr)
  if s == nil then
    return string.format("[FAIL] %s  err=%s", label, tostring(err))
  end
  return string.format("[OK] %s => %s", label, tostring(s))
end

local function run_device_tests()
  local ctx = {}
  local L = {}
  local function add(s)
    L[#L + 1] = s
  end

  add("=== Raw CAS ===")
  add(eval_line("arith", "1+1"))
  add(eval_line("limit", "limit(1/n,n," .. INF .. ")"))
  add(eval_line("sum_geom", "sum((1/2)^n,n,1," .. INF .. ")"))
  add(eval_line("subst", "substitute(n^2,n,4)"))
  add(eval_line("when_lt", 'when(1/2<1,"yes","no")'))

  add("=== calc2 API (ctx=device) ===")
  local ok, v, e = sequences.sequence_term("n^2", 4, ctx)
  add(string.format("sequence_term n^2,4  ok=%s val=%s err=%s", tostring(ok), tostring(v), tostring(e)))

  ok, v, e = sequences.limit_sequence("1/n", ctx)
  add(string.format("limit_sequence 1/n  ok=%s val=%s err=%s", tostring(ok), tostring(v), tostring(e)))

  ok, v, e = series_basics.partial_sum("n", 5, ctx)
  add(string.format("partial_sum n,5  ok=%s val=%s err=%s", tostring(ok), tostring(v), tostring(e)))

  ok, v, e = series_basics.infinite_sum_if_converges("(1/2)^n", ctx)
  add(string.format("infinite_sum (1/2)^n  ok=%s val=%s err=%s", tostring(ok), tostring(v), tostring(e)))

  local sum
  ok, sum, e = series_basics.geometric_series(1, 0.5, ctx)
  add(string.format("geometric_series 1,0.5  ok=%s conv=%s sum=%s err=%s",
    tostring(ok), tostring(sum and sum.converges), tostring(sum and sum.sum_value), tostring(e)))

  local r
  ok, r, e = series_tests.nth_term_test("1/n", ctx)
  add(string.format("nth_term 1/n  verdict=%s lim=%s", tostring(r and r.verdict), tostring(r and r.limit)))

  ok, r, e = series_tests.ratio_test("1/n^2", ctx)
  add(string.format("ratio_test 1/n^2  verdict=%s L=%s", tostring(r and r.verdict), tostring(r and r.L)))

  ok, r, e = series_tests.root_test("1/n^2", ctx)
  add(string.format("root_test 1/n^2  verdict=%s L=%s", tostring(r and r.verdict), tostring(r and r.L)))

  return L
end

function on.paint(gc)
  if display_lines == nil then
    local ok, out = pcall(run_device_tests)
    if ok then
      display_lines = out
    else
      display_lines = { "pcall error: " .. tostring(out) }
    end
  end

  local y = 4
  local h = 12
  for i = 1, #display_lines do
    gc:drawString(display_lines[i], 4, y, "top")
    y = y + h
    if y > 2000 then
      break
    end
  end
end

function on.resize()
  display_lines = nil
  platform.window:invalidate()
end
