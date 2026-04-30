--[[
  calc2.sequences — term evaluation and limits in n (CAS strings use TI-Nspire syntax).
]]

local core = require("calc2.core")

local M = {}

--- Evaluate a_n at index k (k positive integer). a_n is a CAS string in variable n.
function M.sequence_term(a_n, k, ctx)
  core.assert_positive_int(k, "k")
  local expr = string.format("substitute(%s, n, %d)", a_n, k)
  return core.cas_eval(expr, ctx)
end

--- Limit of a_n as n → ∞ (requires CAS).
function M.limit_sequence(a_n, ctx)
  local expr = string.format("limit(%s, n, \u{221E})", a_n)
  return core.cas_eval(expr, ctx)
end

return M
