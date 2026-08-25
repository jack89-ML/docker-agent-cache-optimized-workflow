# Test Results

Validation of the `docker-agent-cache-optimized-workflow` across three runs.
Same base app (FocusPulse, Pomodoro timer), two models, one framework bug in
between. Each test has its own file with the full accounting: computed
cache-hit ratio, planned budget, actual cost, no-cache counterfactual.

| Test | File | Model | App | Cache-hit | Budget | Cost | Saving | Score |
|---|---|---|---|---|---|---|---|---|
| 1 | [test1_v4_PRO.md](test_results/test1_v4_PRO.md) | deepseek-v4-pro | PWA (Windows 11) | 97.2% | $0.60 | ~$0.11 | ~90% | 9.3/10 |
| 2 | [test2_v4_PRO.md](test_results/test2_v4_PRO.md) | deepseek-v4-pro + qwen3.8-max delegation (blocked) | Native Android (APK) | 98.5% | $1.50 | $0.147 | ~94% | 9.0/10 |
| 3 | [test3_qwen38_MAX.md](test_results/test3_qwen38_MAX.md) | qwen3.8-max | PWA (live on :8000) | 99.99% | $10.00 | ~$1.42 (estimated) | ~84% | 9.4/10 |
| 4 | [test4_v4_PRO.md](test_results/test4_v4_PRO.md) | deepseek-v4-pro | Academic review HTS (plain prompt) | 97.5% | $3.00 | $0.096 | — | 9.5/10 |
| 5 | [test5_v4_PRO.md](test_results/test5_v4_PRO.md) | deepseek-v4-pro | Academic review HTS (/goal mode) | 98.9% | $3.00 | $0.134 | — | 9.6/10 |
| 6 | [test6_v4_PRO.md](test_results/test6_v4_PRO.md) | deepseek-v4-pro | Academic review division of labor (/goal) | 96.8% | $3.00 | $0.071 | — | 9.5/10 |

In short: the stable-prefix strategy holds on both models (97-99.99%
cache-read), the real cost is always a fraction of the planned budget, and
the dominant cost lever is output, not input. Tests 4 and 5 extend the
validation to the academic research domain: two runs of the same literature
review, the second started in `/goal` mode, produced 23 and 28 verified
sources respectively for under $0.12 each. Test 2 leaves one branch
unvalidated: delegation to a second model, blocked by a framework bug
(sqlite WAL, issue #55305/#71498), not by the skill.
