# Test 1 — FocusPulse PWA · deepseek-v4-pro

**Status: PASSED** · 2026-08-24 · ~21 min totali (15 attivi) · 0 interventi umani

## Progetto e app

FocusPulse è la web app Pomodoro con cui abbiamo validato il workflow: un
timer 25/5/15 (focus, pausa breve, pausa lunga), statistiche degli ultimi 7
giorni, suono, tema scuro/chiaro, installabile come PWA. Il progetto avviato
per questo test: build completa dell'app dentro un container agent autonomo,
con budget rigido e verifica reale (test, browser, installabilità) al posto
della fiducia. L'app pensata doveva essere rapida da usare da tastiera e da
schermo: presets 25/5 e 50/10, durate personalizzate, scorciatoie, un grafico
a barre dell'ultima settimana e un'icona SVG inline. Niente di più. Il primo
run l'ha prodotta con deepseek-v4-pro da solo, senza delega a un secondo
modello.

## Il conto, senza giri di parole

| Voce | Valore |
|---|---|
| Cache-hit | **97.2%** — 2,527,744 cache-read / (2,527,744 + 72,987 miss) |
| Costo iniziale pensato (budget) | $0.60 |
| Costo totale sostenuto | ~$0.11 (registrato $0.105, tier prezzi legacy) |
| Budget usato | 18% |
| Costo senza cache (controfattuale) | ~$1.16 |
| Risparmio effettivo | ~90% |
| API calls | 35 |
| Input (miss) / output | 72,987 / 74,529 |
| Cache-read | 2,527,744 |

## Setup

| Item | Value |
|---|---|
| Container | `agent-pomodoro` (nousresearch/hermes-agent, non-root uid 10000) |
| Modello | deepseek-v4-pro (API ufficiale), singolo, nessuna delega |
| Contesto | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 file) |
| Task | FocusPulse: PWA Pomodoro installabile per Windows 11 |
| Verifiche | 24/24 task · 28/28 smoke test (rieseguiti in autonomia) |

## Come è andata

- Ha letto i file di contesto nell'ordine previsto e scritto STATUS_SPRINT1..4
  con il costo accumulato in ognuno.
- 4 sprint sequenziali con verifica vera: test Node, curl, validazione
  manifest JSON, criteri di installabilità.
- Ha trovato e corretto un bug reale durante i test (`setBreakType` non
  aggiornava lo stato live).
- Si è costruita da sola una skill di verifica frontend headless dentro il
  proprio container.
- Nessun comando distruttivo, nessun dato inventato, server lasciato su e
  verificato (HTTP 200).

## Verifica della qualità

Funzionamento controllato in browser: start/pausa/reset/skip, accuratezza del
countdown, presets 25/5 e 50/10, durate custom, toggle suono, tema
scuro/chiaro, scorciatoie, grafico 7 giorni, manifest + service worker,
icona SVG inline. Installabilità verificata su Chromium. Giudizio dell'utente
su Windows 11: "UI molto performante e davvero ottima. Nessun bug".

## Voti

| Dimension | Score |
|---|---|
| Autonomia (0 interventi, auto-verifica) | 9.5/10 |
| Efficienza costi (18% del budget) | 10/10 |
| Strategia cache (97.2%, ~90% risparmio) | 9.5/10 |
| Qualità output (verificato dall'utente, nessun bug) | 9/10 |
| Fedeltà al processo (ordine, status file, guardrail) | 9.5/10 |
| **Totale** | **9.3/10** |

## Limiti, detti chiaramente

- Il deliverable è una PWA, non un'app nativa: la specifica diceva PWA, ma
  l'aspettativa dell'utente era nativa. Da qui è nato il Test 2.
- Un solo modello, nessuna delega esercitata.
- La verifica visiva l'ha fatta l'utente a mano, nessun grading automatico
  degli screenshot.
