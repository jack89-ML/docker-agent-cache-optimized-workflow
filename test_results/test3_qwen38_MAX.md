# Test 3 — FocusPulse PWA · qwen3.8-max

**Status: PASSED** · 2026-08-25 · run autonomo · 0 interventi umani

## Progetto e app

Stessa app del Test 1 (FocusPulse PWA), stesso workflow in container, modello
principale diverso: qwen3.8-max (QwenCloud/DashScope, provider alibaba). Il
progetto avviato per questo test: verificare che la strategia cache-first
regga cambiando modello, con i costi letti dai dati reali del database di
telemetria e non dalle stime dell'agente. L'app pensata: identica alla prima
versione, timer Pomodoro scuro ispirato a Linear, un accento cromatico per
modalità (indigo per focus, emerald per la pausa breve, sky per la lunga),
anello di progresso con glow, dialog nativo per le impostazioni, grafico a
barre degli ultimi 7 giorni. Il server è ancora su e risponde: l'app vive su
`http://192.168.1.187:8000/`.

## Il conto, senza giri di parole

Dati letti dal `state.db` del container (tabella `session_model_usage`,
provider alibaba) dopo il run. Non stime: misurazioni.

| Voce | Valore |
|---|---|
| Cache-hit | **99.99%** — 4,120,902 cache-read / (4,120,902 + 558 miss) |
| Costo iniziale pensato (budget) | $10.00 |
| Costo totale sostenuto | ~$1.42 stimato a prezzi di listino (il DB non ha finalizzato: `cost_status` unknown) |
| Budget usato | ~14% |
| Costo senza cache (controfattuale) | ~$8.63 (4,121,460 miss × $2/M + output) |
| Risparmio effettivo | ~84% |
| API calls | 92 (28 + 64) |
| Input (miss) / output | 558 / 64,479 |
| Cache-read / cache-write | 4,120,902 / 419,454 |

La parte scomoda, detta chiaramente: l'agente, dentro il suo report, aveva
stimato cache-hit ~21% e costo ~$0.63. Era sbagliato su entrambi i fronti:
non ha accesso alla telemetria del provider e ha tirato a indovinare sul
riuso del prefisso. I dati veri dicono 99.99% di cache-hit e ~$1.42 di costo
stimato. La strategia del prefisso stabile ha funzionato con qwen3.8-max
esattamente come con deepseek.

## Setup

| Item | Value |
|---|---|
| Container | `agent-qwen-test` (nousresearch/hermes-agent) |
| Modello | qwen3.8-max (QwenCloud/DashScope), primario, nessuna delega |
| Contesto | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 file) |
| Task | FocusPulse: PWA Pomodoro (backend FastAPI, timer JS vanilla, grafici, impostazioni) |
| Verifiche | 10/10 task · 14 pytest (10 API + 4 smoke) · 10 test JS timer · endpoint tutti 200 |

## Come è andata

- Ordine dei file di contesto rispettato, STATUS scritti con costo
  accumulato, verifica reale a ogni task (curl, pytest, unit test Node).
- Ha usato l'unica skill UI caricabile (`popular-web-designs`, template
  Linear) e ha riportato onestamente che le altre 5 erano symlink rotti nel
  container (puntavano a una directory inesistente), applicando i loro
  principi anti-slop da conoscenza generale.
- Nessun Chrome di sistema e `playwright install chromium` falliva: ha
  trovato un headless-shell già presente sull'immagine, compatibile con la
  sua versione di Playwright, e la verifica visiva è stata reale.

## Bug trovati e corretti durante il run

Visti solo dal browser, i test pytest non potevano vederli:

1. `index.html` non caricava `timer.js` (`FocusPulseTimer is not defined`):
   l'app era completamente morta. Corretto aggiungendo il tag script.
2. Il reset globale `*{margin:0}` azzerava i margini auto del `<dialog>`
   nativo, lasciando le impostazioni incastrate in alto a sinistra.
   Corretto con `margin:auto` sulla classe del dialog.

## Voti

| Dimension | Score |
|---|---|
| Autonomia (0 interventi, auto-verifica) | 9.5/10 |
| Efficienza costi (~14% del budget, stimato) | 9/10 |
| Strategia cache (99.99% misurato dal state.db) | 10/10 |
| Qualità output (app funzionante, verificata in browser, 2 bug reali trovati e corretti) | 9/10 |
| Fedeltà al processo (status file, blocchi riportati onestamente, nessuna invenzione) | 9.5/10 |
| **Totale** | **9.4/10** |

## Limiti, detti chiaramente

- Il costo è stimato a prezzi di listino: il DB ha lasciato `cost_status`
  unknown per questo provider, quindi l'importo esatto fatturato non è
  verificato.
- Le stime di costo dell'agente vanno trattate come approssimative. La
  telemetria del state.db è la fonte di verità per i rapporti di cache; i
  costi vanno ricalcolati a listino finché il DB non finalizza il billing
  per provider terzi.
- Modello singolo, nessuna delega: il percorso di delega era bloccato dal
  bug upstream del WAL sqlite (#55305/#71498), già visto nel Test 2. Un run
  con worker Qwen sotto orchestratore DeepSeek è il follow-up naturale.
- Nessun grading automatico degli screenshot.
