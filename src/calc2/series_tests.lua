--[[
  calc2.series_tests — nth-term, geometric ratio, p-series, ratio test (CAS).
]]

local core = require("calc2.core")

local M = {}

--- Classify geometric series by ratio r (number or CAS string).
function M.geometric_test_ratio(r, ctx)
  core.clear_steps()
  local rstr = type(r) == "number" and tostring(r) or "(" .. tostring(r) .. ")"
  core.step("Series", "\\sum ar^n is geometric with common ratio r.")
  core.step("Rule", "Converges if and only if |r| < 1 (for the standard infinite geometric series).")

  if type(r) == "number" then
    local ar = math.abs(r)
    core.step("|r|", string.format("|r| = %g", ar))
    if ar < 1 then
      core.step("Conclusion", "|r| < 1 \\Rightarrow converges.")
      return true, { converges = true, reason = "|r|<1" }, nil
    else
      core.step("Conclusion", "|r| \\ge 1 \\Rightarrow diverges.")
      return true, { converges = false, reason = "|r|>=1" }, nil
    end
  end

  local ok, s, err = core.cas_eval(string.format("when(abs(%s)<1, \"conv\", \"div\")", rstr), ctx)
  if not ok then
    return false, nil, err
  end
  if s == "conv" then
    core.step("Conclusion", "|r| < 1 \\Rightarrow converges.")
    return true, { converges = true, reason = "cas" }, nil
  end
  if s == "div" then
    core.step("Conclusion", "|r| \\ge 1 \\Rightarrow diverges.")
    return true, { converges = false, reason = "cas" }, nil
  end
  core.step("Conclusion", "CAS returned: " .. tostring(s))
  return true, { converges = nil, reason = "unknown" }, nil
end

--- p-series \\sum 1/n^p: converges iff p > 1.
function M.p_series_classify(p, ctx)
  core.clear_steps()
  core.step("Series", "p-series: \\sum_{n=1}^{\\infty} 1/n^p.")
  core.step("Rule", "Converges if and only if p > 1.")

  if type(p) == "number" then
    core.step("p", string.format("Here p = %g.", p))
    if p > 1 then
      core.step("Conclusion", "p > 1 \\Rightarrow converges.")
      return true, { converges = true }, nil
    else
      core.step("Conclusion", "p \\le 1 \\Rightarrow diverges.")
      return true, { converges = false }, nil
    end
  end

  local pstr = "(" .. tostring(p) .. ")"
  local ok, s, err = core.cas_eval(string.format("when(%s>1, \"conv\", \"div\")", pstr), ctx)
  if not ok then
    return false, nil, err
  end
  if s == "conv" then
    core.step("Conclusion", "p > 1 \\Rightarrow converges.")
    return true, { converges = true }, nil
  end
  if s == "div" then
    core.step("Conclusion", "p \\le 1 \\Rightarrow diverges.")
    return true, { converges = false }, nil
  end
  return true, { converges = nil }, nil
end

--- nth term test for \\sum a_n: if lim a_n \\ne 0 then diverges; if 0, inconclusive.
function M.nth_term_test(a_n, ctx)
  core.clear_steps()
  core.step("Test", "nth term test for divergence: if \\lim_{n\\to\\infty} a_n \\ne 0 then \\sum a_n diverges.")
  local lim_expr = string.format("limit(%s, n, \u{221E})", a_n)
  local ok, lim, err = core.cas_eval(lim_expr, ctx)
  if not ok then
    return false, nil, err
  end
  core.step("Limit", string.format("\\lim_{n\\to\\infty} a_n = %s", lim))

  local okz, isz, errz = core.cas_eval(string.format("when(%s = 0, \"zero\", \"nonzero\")", lim), ctx)
  if okz and isz == "nonzero" then
    core.step("Conclusion", "Limit is not 0 \\Rightarrow series diverges.")
    return true, { verdict = "diverges", limit = lim }, nil
  end
  if okz and isz == "zero" then
    core.step("Conclusion", "Limit is 0 \\Rightarrow nth term test is inconclusive.")
    return true, { verdict = "inconclusive", limit = lim }, nil
  end

  core.step("Conclusion", "Could not decide zero vs nonzero from CAS; inspect the limit manually.")
  return true, { verdict = "unknown", limit = lim }, errz
end

--- Ratio test: L = lim |a_{n+1}/a_n|. L < 1 abs conv, L > 1 div, L = 1 inconclusive.
function M.ratio_test(a_n, ctx)
  core.clear_steps()
  core.step("Test", "Ratio test: L = \\lim_{n\\to\\infty} |a_{n+1}/a_n|.")
  local ratio = string.format("abs(substitute(%s, n, n+1)/(%s))", a_n, a_n)
  local lim_expr = string.format("limit(%s, n, \u{221E})", ratio)
  local ok, lim, err = core.cas_eval(lim_expr, ctx)
  if not ok then
    return false, nil, err
  end
  core.step("Ratio", string.format("|a_{n+1}/a_n| = %s", ratio))
  core.step("Limit", string.format("L = %s", lim))

  local oklt, lt1, errlt = core.cas_eval(string.format("when(%s < 1, \"abs_conv\", \"_\")", lim), ctx)
  if oklt and lt1 == "abs_conv" then
    core.step("Conclusion", "L < 1 \\Rightarrow absolute convergence.")
    return true, { verdict = "absolute_convergence", L = lim }, nil
  end
  local okgt, gt1, errgt = core.cas_eval(string.format("when(%s > 1, \"div\", \"_\")", lim), ctx)
  if okgt and gt1 == "div" then
    core.step("Conclusion", "L > 1 \\Rightarrow divergence.")
    return true, { verdict = "diverges", L = lim }, nil
  end
  local okeq, eq1, erreq = core.cas_eval(string.format("when(%s = 1, \"inc\", \"_\")", lim), ctx)
  if okeq and eq1 == "inc" then
    core.step("Conclusion", "L = 1 \\Rightarrow ratio test inconclusive.")
    return true, { verdict = "inconclusive", L = lim }, nil
  end

  core.step("Conclusion", "Could not classify L automatically; compare L to 1 manually.")
  return true, { verdict = "unknown", L = lim }, erreq or errgt or errlt
end

--- Root test: L = lim |a_n|^(1/n). Same conclusions as ratio test for L vs 1.
function M.root_test(a_n, ctx)
  core.clear_steps()
  core.step("Test", "Root test: L = \\lim_{n\\to\\infty} |a_n|^{1/n}.")
  local expr = string.format("limit((abs(%s))^(1/n), n, \u{221E})", a_n)
  local ok, lim, err = core.cas_eval(expr, ctx)
  if not ok then
    return false, nil, err
  end
  core.step("Root", string.format("|a_n|^{1/n} simplifies toward L = %s", lim))

  local oklt, lt1 = core.cas_eval(string.format("when(%s < 1, \"abs_conv\", \"_\")", lim), ctx)
  if oklt and lt1 == "abs_conv" then
    core.step("Conclusion", "L < 1 \\Rightarrow absolute convergence.")
    return true, { verdict = "absolute_convergence", L = lim }, nil
  end
  local okgt, gt1 = core.cas_eval(string.format("when(%s > 1, \"div\", \"_\")", lim), ctx)
  if okgt and gt1 == "div" then
    core.step("Conclusion", "L > 1 \\Rightarrow divergence.")
    return true, { verdict = "diverges", L = lim }, nil
  end
  local okeq, eq1 = core.cas_eval(string.format("when(%s = 1, \"inc\", \"_\")", lim), ctx)
  if okeq and eq1 == "inc" then
    core.step("Conclusion", "L = 1 \\Rightarrow root test inconclusive.")
    return true, { verdict = "inconclusive", L = lim }, nil
  end

  core.step("Conclusion", "Could not classify L automatically; compare L to 1 manually.")
  return true, { verdict = "unknown", L = lim }, nil
end

return M
