# Calc 2 (sequences & series) — Lua function catalog and costing

This document scopes a **TI‑Nspire CX CAS** Lua layer: **pedagogical helpers** that call the built‑in CAS where appropriate and emit **step text** your UI renders. Costs are **implementation effort**, not runtime.

## Costing legend

| Tier | Meaning | Typical scope |
|------|---------|----------------|
| **S** | Small | Thin wrapper around one CAS call + formatted output |
| **M** | Medium | Multi‑branch logic, validation, or several CAS steps with narration |
| **L** | Large | Full test implementation with edge cases, optional proofs, or heavy symbolic prep |

Rough **story points** (planning only): S ≈ 1–2, M ≈ 3–5, L ≈ 8–13.

---

## 1. Core / shared

| Function | Purpose | Tier | Notes |
|----------|---------|------|--------|
| `cas_eval(expr)` | Safe evaluation of a CAS string; normalize errors | S | Foundation for everything |
| `format_expr(expr)` | Pretty math string for display (LaTeX or Nspire text) | M | Depends on how you render in Lua |
| `step(title, body)` | Append one numbered step to a session buffer | S | Pedagogy backbone |
| `clear_steps()` | Reset session | S | — |
| `assert_positive_int(n, name)` | Guard indices, terms, partial sum counts | S | — |
| `tolerance()` / `near(a, b)` | Float comparison for numeric checks | S | Useful for ratio/root limits |

---

## 2. Sequences

| Function | Purpose | Tier | Notes |
|----------|---------|------|--------|
| `sequence_term(a_n, n)` | Evaluate \(a_n\) for symbolic or numeric `n` | S | Wrap `substitute` / direct eval |
| `limit_sequence(a_n)` | \(\lim_{n\to\infty} a_n\) | S | CAS `limit` |
| `limit_subsequence_squeeze(...)` | Guided squeeze / sandwich (user supplies bounds) | M | Steps are mostly templated |
| `monotone_check(a_n)` | Sign of \(a_{n+1}-a_n\) or \(a_{n+1}/a_n\) | M | May need assumptions |
| `bounded_hint(a_n)` | Optional bound reasoning (bounded/unbounded) | L | Hard to automate generally |

---

## 3. Partial sums and series basics

| Function | Purpose | Tier | Notes |
|----------|---------|------|--------|
| `partial_sum(a_n, k)` | \(\sum_{n=1}^{k} a_n\) | S | CAS `sum` |
| `infinite_sum_if_converges(a_n)` | Sum when CAS knows closed form | S | Often black‑box |
| `geometric_series(a, r)` | \(\sum ar^n\): convergence, sum, partial sum | M | Full step template |
| `telescoping_partial(a_n, k)` | Partial sum when `a_n = b_{n+1}-b_n` (user or CAS `part` discovery) | L | Discovery is the hard part |
| `harmonic_partial(k)` | \(H_k\) with optional asymptotic / bound steps | M | — |

---

## 4. Convergence tests (infinite series \(\sum a_n\))

| Function | Purpose | Tier | Notes |
|----------|---------|------|--------|
| `nth_term_test(a_n)` | If \(\lim a_n \neq 0\) ⇒ diverge | M | Include limit step |
| `geometric_test_ratio(r)` | Decide by \|r\| | S | Templated |
| `p_series_classify(p)` | \(\sum 1/n^p\) | S | Templated |
| `integral_test(a_n, f_x, monotone_positive_assumed)` | Compare to \(\int_1^\infty f\) | L | Needs \(f\) mapping \(n\mapsto x\); monotone disclaimer |
| `comparison_test(a_n, b_n, direction)` | Direct comparison scaffolding | M | User picks comparator; you verify inequalities |
| `limit_comparison_test(a_n, b_n)` | Limit of \(a_n/b_n\) | M | Several CAS substeps |
| `ratio_test(a_n)` | \(\lim \|a_{n+1}/a_n\|\) | M | Very common in Calc 2 |
| `root_test(a_n)` | \(\lim \|a_n\|^{1/n}\) | M | — |
| `alternating_series_test((-1)^n b_n, b_n)` | Leibniz: \(b_n\searrow 0\) | L | Monotonicity check is symbolic pain |
| `absolute_convergence(a_n)` | Test \(\sum \|a_n\|\) via chosen test | M | Orchestrator |
| `conditional_vs_absolute_summary(...)` | Narrate absolute vs conditional | S | Text layer |

---

## 5. Power series

| Function | Purpose | Tier | Notes |
|----------|---------|------|--------|
| `power_series_centered(c_n, x, a)` | \(\sum c_n (x-a)^n\) object | S | Data structure + string |
| `radius_ratio(c_n)` | Ratio formula for \(R\) | M | Careful with factorials / gaps |
| `radius_root(c_n)` | Cauchy–Hadamard style when simpler | M | — |
| `interval_of_convergence(...)` | \(R\), then endpoints \(x=a\pm R\) | L | Endpoint series are separate tests each |
| `differentiate_integrate_series(...)` | Term‑wise ops inside interval | M | State radius unchanged (with caveats) |

---

## 6. Taylor / Maclaurin

| Function | Purpose | Tier | Notes |
|----------|---------|------|--------|
| `taylor(f, x, a, order)` | CAS `taylor` wrapper + step | S | — |
| `maclaurin(f, x, order)` | `a = 0` | S | — |
| `taylor_coefficient_formula(k)` | \(f^{(k)}(a)/k!\) scaffolding | M | User supplies derivatives or CAS |
| `remainder_lagrange(...)` | Optional bound template | L | Needs derivative max on interval |
| `remainder_alternating_bound(...)` | Leibniz remainder for alternating | M | — |
| `taylor_approx_error(f, a, order, x)` | Orchestrate bound + numeric error | L | Combines several ideas |

---

## 7. Applications (often Calc 2 tail)

| Function | Purpose | Tier | Notes |
|----------|---------|------|--------|
| `series_to_function_approx(...)` | Replace function by polynomial approx | M | Wraps Taylor |
| `binomial_series((1+x)^k, order)` | General exponent | M | Branch \|x\| < 1 |
| `known_series_substitute(...)` | Replace \(x\) by \(x^2\), \(-x\), etc. | M | Recompute radius |

---

## 8. Optional (curriculum‑dependent)

Include only if your Calc 2 scope covers them; otherwise backlog.

| Function | Purpose | Tier |
|----------|---------|------|
| `parametric_arc_length` / `polar_area` | If param/polar is in your Calc 2 | M–L |
| `sequence_recurrence_solve` | Closed form from recurrence | L |

---

## Rollout order (suggested)

1. **Core** (`cas_eval`, `step`, guards) — unblocks everything.  
2. **Geometric + p‑series + nth term** — high coverage, easy wins.  
3. **Ratio + root + limit comparison** — bulk of “standard” homework.  
4. **Integral + alternating** — heavier symbolic assumptions.  
5. **Power series \(R\) + endpoints** — orchestration heavy.  
6. **Taylor + remainders** — CAS helps; bounds remain custom.

---

## Effort rollup (order of magnitude)

| Area | Count (approx) | Mix S/M/L | Notes |
|------|----------------|-----------|--------|
| Core | ~6 | mostly S | One‑time platform glue |
| Sequences | ~5 | S–M | Bounded/monotone L is skippable v1 |
| Series basics | ~5 | S–M | Telescoping L optional |
| Tests | ~12 | M–L | Alternating + integral are the long poles |
| Power / Taylor | ~10 | M–L | Endpoint automation is largest |

**Ballpark:** ~40 named public functions for solid Calc 2 coverage; **~15–20** are “must have” for a credible first release; the rest deepen quality and edge cases.

---

## Repository next steps

- Add `src/` Lua modules mirroring sections above (e.g. `series_tests.lua`, `power_series.lua`).  
- Each function returns `{ result, steps, warnings }` for a single UI pattern.  
- Track implementation status in GitHub **Issues** or a **Project** column per function name from the tables above.

---

## Implementation status (rolling)

| Module | Path | Implemented |
|--------|------|-------------|
| Core | `src/calc2/core.lua` | `clear_steps`, `step`, `get_steps`, `tolerance`, `near`, `assert_positive_int`, `cas_eval`, `format_expr` |
| Sequences | `src/calc2/sequences.lua` | `sequence_term`, `limit_sequence` |
| Series basics | `src/calc2/series_basics.lua` | `partial_sum`, `infinite_sum_if_converges`, `geometric_series` |
| Series tests | `src/calc2/series_tests.lua` | `geometric_test_ratio`, `p_series_classify`, `nth_term_test`, `ratio_test`, `root_test` |

**Device:** set `package.path` so `require("calc2.core")` resolves (e.g. prepend `src/?.lua`). CAS calls use `math.evalStr` unless you pass `ctx.evalStr` (used by desktop tests).

**Desktop CI:** `lua5.4 tests/smoke.lua` (mock CAS; extend `tests/smoke.lua` as you add features).
