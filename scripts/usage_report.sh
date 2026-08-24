#!/usr/bin/env bash
# ============================================================================
# usage_report.sh — zero-token cost/cache report from a Hermes state.db
# Usage: bash usage_report.sh <state.db> [hours]
#   <state.db>  path to the Hermes SQLite DB (default: /opt/data/state.db)
#   [hours]     lookback window (default: 24)
#
# Reads the session_model_usage table (input_tokens, output_tokens,
# cache_read_tokens, cache_write_tokens, estimated_cost_usd) and prints a
# compact report. Designed to run under a no_agent cron job: stable output,
# safe to hash-dedup (send only when the output changes).
# ============================================================================
set -euo pipefail

DB="${1:-/opt/data/state.db}"
HOURS="${2:-24}"

if [ ! -f "$DB" ]; then
  echo "ERROR: state.db not found at $DB"
  exit 1
fi

python3 - "$DB" "$HOURS" << 'PY'
import sqlite3, sys, time

db_path, hours = sys.argv[1], float(sys.argv[2])
since = time.time() - hours * 3600
conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
try:
    rows = conn.execute("""
        SELECT model, count(*), sum(api_call_count),
               sum(input_tokens), sum(output_tokens),
               sum(cache_read_tokens), sum(cache_write_tokens),
               sum(estimated_cost_usd)
        FROM session_model_usage
        WHERE first_seen >= ?
        GROUP BY model ORDER BY sum(estimated_cost_usd) DESC
    """, (since,)).fetchall()
finally:
    conn.close()

if not rows:
    print(f"usage_report: no usage in the last {hours:g}h")
    sys.exit(0)

print(f"usage_report · last {hours:g}h · {len(rows)} model(s)")
tot_calls = tot_in = tot_out = tot_cr = tot_cw = 0
tot_cost = 0.0
for model, n, calls, inn, out, cr, cw, cost in rows:
    calls = calls or 0; inn = inn or 0; out = out or 0
    cr = cr or 0; cw = cw or 0; cost = cost or 0.0
    hit = cr / (cr + inn) * 100 if (cr + inn) else 0.0
    print(f"  {model:<24} calls={calls:>5} in={inn:>9,} out={out:>8,} "
          f"cacheR={cr:>12,} cacheW={cw or 0:>7,} hit={hit:5.1f}% est=${cost:.4f}")
    tot_calls += calls; tot_in += inn; tot_out += out
    tot_cr += cr; tot_cw += cw; tot_cost += cost

tot_hit = tot_cr / (tot_cr + tot_in) * 100 if (tot_cr + tot_in) else 0.0
print(f"  TOTAL{'':<18} calls={tot_calls:>5} in={tot_in:>9,} out={tot_out:>8,} "
      f"cacheR={tot_cr:>12,} cacheW={tot_cw or 0:>7,} hit={tot_hit:5.1f}% est=${tot_cost:.4f}")
PY
