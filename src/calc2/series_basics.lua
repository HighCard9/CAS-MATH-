--[[
  calc2.series_basics — partial sums, CAS infinite sums, geometric series steps.
]]

local core = require("calc2.core")

local M = {}

--- Sum of a_n for n = 1 .. k (CAS).
function M.partial_sum(a_n, k, ctx)
  core.assert_positive_int(k, "k")
  local expr = string.format("sum(%s, n, 1, %d)", a_n, k)
  return core.cas_eval(expr, ctx)
end

--- Infinite sum when the CAS can evaluate it (may return undef / unevaluated).
function M.infinite_sum_if_converges(a_n, ctx)
  local expr = string.format("sum(%s, n, 1, \u{221E})", a_n)
  return core.cas_eval(expr, ctx)
end

--- Geometric series sum_{n=0}^∞ a r^n. a and r may be numbers or CAS strings.
--- Returns ok, summary_table, err — summary has convergence, sum, steps (via core.step).
function M.geometric_series(a, r, ctx)
  core.clear_steps()
  local astr = type(a) == "number" and tostring(a) or "(" .. tostring(a) .. ")"
  local rstr = type(r) == "number" and tostring(r) or "(" .. tostring(r) .. ")"

  core.step("Series", string.format("Consider \\sum_{n=0}^{\\infty} (%s)(%s)^n", astr, rstr))

  if type(r) == "number" then
    local ar = math.abs(r)
    core.step("|r|", string.format("|r| = |%s| = %g", rstr, ar))
    if ar < 1 then
      local sum = astr .. "/(1-(" .. rstr .. "))"
      core.step("Convergence", "|r| < 1, so the geometric series converges.")
      core.step("Sum", string.format("S = a/(1-r) = %s", sum))
      local ok, val, err = core.cas_eval(sum, ctx)
      return ok, { converges = true, sum_expr = sum, sum_value = val, steps = core.get_steps() }, err
    elseif ar >= 1 then
      core.step("Convergence", "|r| \\ge 1, so the geometric series diverges (terms do not go to 0).")
      return true, { converges = false, sum_expr = nil, sum_value = nil, steps = core.get_steps() }, nil
    end
  end

  -- Symbolic r: ask CAS for |r| < 1 branch when possible
  local ok_cmp, cmp, err = core.cas_eval(string.format("when(abs(%s)<1, 1, 0)", rstr), ctx)
  if ok_cmp and cmp == "1" then
    local sum = astr .. "/(1-(" .. rstr .. "))"
    core.step("Convergence", "CAS: |r| < 1, so the series converges.")
    core.step("Sum", string.format("S = a/(1-r) = %s", sum))
    local ok2, val, err2 = core.cas_eval(sum, ctx)
    return ok2, { converges = true, sum_expr = sum, sum_value = val, steps = core.get_steps() }, err2
  end
  if ok_cmp and cmp == "0" then
    core.step("Convergence", "CAS: |r| \\ge 1 (or unknown); geometric series does not converge in the usual sense.")
    return true, { converges = false, sum_expr = nil, sum_value = nil, steps = core.get_steps() }, nil
  end

  core.step("Convergence", "Could not classify |r| symbolically; use ratio test or numeric |r|.")
  return false, { converges = nil, sum_expr = nil, sum_value = nil, steps = core.get_steps() }, err or "symbolic_r_failed"
end

return M
