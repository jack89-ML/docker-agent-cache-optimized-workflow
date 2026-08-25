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

In short: the stable-prefix strategy holds on both models (97-99.99%
cache-read), the real cost is always a fraction of the planned budget, and
the dominant cost lever is output, not input. Test 2 leaves one branch
unvalidated: delegation to a second model, blocked by a framework bug
(sqlite WAL, issue #55305/#71498), not by the skill.
