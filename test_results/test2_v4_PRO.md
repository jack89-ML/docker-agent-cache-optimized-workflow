# Test 2 — FocusPulse Android (nativa) · deepseek-v4-pro + delega qwen3.8-max

**Status: PASSED** · 2026-08-24 · ~26 min · 0 interventi durante la build, 1 passaggio di valutazione dopo

## Progetto e app

FocusPulse versione nativa Android (Kotlin + Jetpack Compose): la stessa
logica Pomodoro della PWA, ma come app installabile da APK. Il progetto
avviato per questo test: esercitare la delega a un secondo modello
(qwen3.8-max) sotto un orchestratore deepseek-v4-pro, con budget $1.50.
L'app pensata: timer con presets, impostazioni suono, installabile sul
Samsung A137F. Il risultato, detto senza addolcirlo: funziona, ma la UI è
uscita basic. L'utente ha chiesto il suono e i bottoni +/- per i minuti,
entrambi sistemati nel passaggio di valutazione dopo il run.

## Il conto, senza giri di parole

| Voce | Valore |
|---|---|
| Cache-hit | **98.5%** — 5,141,888 cache-read / (5,141,888 + 77,634 miss) |
| Costo iniziale pensato (budget) | $1.50 |
| Costo totale sostenuto | $0.147 (registrato) |
| Budget usato | 10% |
| Costo senza cache (controfattuale) | ~$2.39 |
| Risparmio effettivo | ~94% |
| API calls | 67 |
| Input (miss) / output | 77,634 / 109,198 |
| Cache-read | 5,141,888 |

## Setup

| Item | Value |
|---|---|
| Container | `agent-focuspulse` (nousresearch/hermes-agent) |
| Modello | deepseek-v4-pro (API ufficiale) + delega configurata a qwen3.8-max (provider alibaba) |
| Contesto | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 file) |
| Task | FocusPulse: app Android nativa (Kotlin + Jetpack Compose) |
| Verifiche | 4/4 sprint · aapt dump badging PASS · installazione APK PASS · avvio + zero crash PASS |

## Come è andata

- Stesso rigore del Test 1: ordine dei file di contesto, STATUS con costi
  accumulati, verifica reale a ogni sprint (gradle build, unit test).
- La parte da raccontare senza trucchi: la delega a qwen3.8-max era
  configurata ma è stata bloccata da un bug del framework (corruzione del
  WAL sqlite in `async_delegation.py`, issue upstream #55305/#71498). Non è
  un fallimento della skill: l'agente ha documentato il blocco, salvato una
  nota in memoria per non ridiagnosticare, e implementato il design
  direttamente con DeepSeek. La delega, quindi, non è mai stata esercitata.

## Fix dopo il run (valutazione dell'utente)

Giudizio: "App funzionante. Molto BASIC questa volta. Nessun suono, bug nei
bottoni +/- per incrementare minuti. Però BASIC ma funzionale."

1. Bottoni +/-: `coerceAtLeast(1)` applicava solo il minimo, mai il massimo,
   e il valore poteva sforare il limite disabilitando i bottoni in modo
   incoerente. Sostituito con `coerceIn(1,180)`, `coerceIn(1,60)`,
   `coerceIn(1,60)`, `coerceIn(1,12)`. Rebuild: BUILD SUCCESSFUL.
2. Suono: esisteva solo nella notifica (`setSound`), che non scatta quando
   l'app è in primo piano. Aggiunto doppio beep `ToneGenerator` in
   `MainViewModel.onPhaseCompleted`, gestito dall'impostazione Sound
   esistente.
3. Reinstallata sul Samsung A137F: Success, app in primo piano, zero crash.

## Voti

| Dimension | Score |
|---|---|
| Autonomia (0 interventi durante la build) | 9/10 |
| Efficienza costi (10% del budget) | 10/10 |
| Strategia cache (98.5%, ~94% risparmio) | 9.5/10 |
| Qualità output (funzionale, UI basic, verificato dall'utente) | 7/10 |
| Fedeltà al processo (ordine, status file, blocco riportato onestamente) | 9.5/10 |
| **Totale** | **9.0/10** |

## Limiti, detti chiaramente

- La delega al secondo modello non è stata esercitata: il bug WAL del
  framework l'ha bloccata. Un run su framework corretto è il follow-up
  naturale.
- UI funzionale ma basic (feedback utente): il passaggio di design con Qwen
  via chiamata API diretta (bypassando il bug WAL) è il passo raccomandato.
- Nessun grading automatico degli screenshot, verifica visiva umana sul
  dispositivo.
