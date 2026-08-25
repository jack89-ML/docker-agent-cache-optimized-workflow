# Test Results

Validazione del workflow `docker-agent-cache-optimized-workflow` su tre run.
Stessa app di base (FocusPulse, timer Pomodoro), due modelli, un bug di
framework in mezzo. Ogni test ha il suo file con il conto completo: cache-hit
calcolato, budget pensato, costo sostenuto, controfattuale senza cache.

| # | File | Modello | App | Cache-hit | Budget | Costo sostenuto | Risparmio vs senza cache | Voto |
|---|---|---|---|---|---|---|---|---|
| 1 | [test1_v4_PRO.md](test_results/test1_v4_PRO.md) | deepseek-v4-pro | PWA (Windows 11) | 97.2% | $0.60 | ~$0.11 | ~90% | 9.3/10 |
| 2 | [test2_v4_PRO.md](test_results/test2_v4_PRO.md) | deepseek-v4-pro + delega qwen3.8-max (bloccata da bug) | Android nativa (APK) | 98.5% | $1.50 | $0.147 | ~94% | 9.0/10 |
| 3 | [test3_qwen38_MAX.md](test_results/test3_qwen38_MAX.md) | qwen3.8-max | PWA (live su :8000) | 99.99% | $10.00 | ~$1.42 (stimato) | ~84% | 9.4/10 |

In breve: la strategia del prefisso stabile regge su entrambi i modelli
(97-99.99% di cache-read), il costo reale è sempre una frazione del budget
pensato, e la leva di costo dominante è l'output, non l'input. Il Test 2
lascia aperto l'unico ramo non validato: la delega a un secondo modello,
bloccata da un bug del framework (sqlite WAL, issue #55305/#71498), non
dalla skill.
