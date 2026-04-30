--[[
  CAS smoke page for TI-Nspire CX CAS (Lua script in a Geometry / Notes page).

  Paste this entire script into the Lua editor on the handheld or in Student Software.

  Important: math.evalStr only works after the page is running (e.g. inside on.paint).
  This script never calls the math server during load.

  After saving, leave and re-open the page, or run once; results appear as lines of text.
]]

local INF = "\226\136\158" -- UTF-8 infinity (U+221E), works on Nspire Lua 5.1

local results = {}
local results_ready = false
local err_load = nil

local function eval_line(label, expr)
  local s, err = math.evalStr(expr)
  if s == nil then
    return string.format("%s  FAIL  %s  |  err=%s", label, expr, tostring(err))
  end
  return string.format("%s  OK  %s  =>  %s", label, expr, tostring(s))
end

local function run_all_cas_checks()
  local r = {}
  r[#r + 1] = "CAS smoke (first paint)"
  r[#r + 1] = eval_line("arith", "1+1")
  r[#r + 1] = eval_line("limit", "limit(1/n,n," .. INF .. ")")
  r[#r + 1] = eval_line("sum_geom", "sum((1/2)^n,n,1," .. INF .. ")")
  r[#r + 1] = eval_line("subst", "substitute(n^2,n,4)")
  r[#r + 1] = eval_line("ratio_lim", "limit(abs(substitute(1/n^2,n,n+1)/(1/n^2)),n," .. INF .. ")")
  r[#r + 1] = eval_line("when_lt", 'when(1/2<1,"yes","no")')
  return r
end

function on.paint(gc)
  if not results_ready then
    local ok, out = pcall(run_all_cas_checks)
    if ok then
      results = out
    else
      results = { "pcall error: " .. tostring(out) }
    end
    results_ready = true
  end

  local y = 8
  for i = 1, #results do
    gc:drawString(results[i], 6, y, "top")
    y = y + 14
  end
  if err_load then
    gc:drawString(err_load, 6, y, "top")
  end
end

function on.resize()
  results_ready = false
  platform.window:invalidate()
end

-- Optional: uncomment to force re-run when the page gains focus (OS-dependent).
-- function on.activate() results_ready = false platform.window:invalidate() end
