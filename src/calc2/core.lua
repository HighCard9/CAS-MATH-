--[[
  calc2.core — session steps, CAS wrapper, small guards (TI-Nspire Lua + desktop stub).

  On device: uses math.evalStr(expr). Optional ctx.evalStr overrides (tests).
]]

local M = {}

local step_buffer = {}

function M.clear_steps()
  step_buffer = {}
end

--- Append one step; returns the step table for callers who want to mutate.
function M.step(title, body)
  local s = { title = title or "", body = body or "" }
  step_buffer[#step_buffer + 1] = s
  return s
end

function M.get_steps()
  return step_buffer
end

--- Default floating tolerance for numeric helpers (not used by CAS strings).
function M.tolerance()
  return 1e-9
end

function M.near(a, b)
  local t = M.tolerance()
  return math.abs(a - b) <= t * (1 + math.max(math.abs(a), math.abs(b)))
end

function M.assert_positive_int(n, name)
  name = name or "n"
  if type(n) ~= "number" or n ~= math.floor(n) or n < 1 then
    error(name .. " must be a positive integer")
  end
end

--- Evaluate a CAS expression string. Returns ok, value_string, err_code/string.
function M.cas_eval(expr, ctx)
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

--- Pass-through for display; later can map to LaTeX or Nspire pretty print.
function M.format_expr(expr)
  return tostring(expr or "")
end

return M
