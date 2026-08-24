# MASTER PLAN — <PROJECT_NAME>

> Stato: **PRONTO PER SPRINT 1** · Eseguito da: agente autonomo <MODEL_A> + subagente <MODEL_B>
> Documento di riferimento: `CONTEXT.md` (obbligatorio leggerlo PRIMA)

## ARCHITETTURA TARGET

```
<diagramma ASCII: sorgente dati → servizio/API → app/client>
```

**REGOLE D'ORO DELL'ARCHITETTURA (vincolanti)**:
1. MAI eseguire script CLI a ogni richiesta (lento + lock su DB).
2. MAI scrivere su dati di produzione dal servizio (sola lettura, WAL).
3. Cache in memoria; invalidazione SOLO su evento di aggiornamento dati.
4. Zero dipendenze pesanti nel servizio.
5. Accesso SOLO via LAN/VPN — MAI esposto su Internet.

## SPRINT PLAN (4 sprint sequenziali + fase 0)

### FASE 0 — Documentazione (immediata)
- [x] CONTEXT.md nel workspace del container
- [x] Master plan (questo file)
- [ ] Verificare che il container legga entrambi i file

### SPRINT 1 — <NOME> (modello: <X>)
**Obiettivo**: <descrizione>

Task: <elenco 1.1-1.13 dalla task list>
**Done = <criterio di completamento misurabile>**

### SPRINT 2 — <NOME> (modello: <X>)
**Obiettivo**: <descrizione>
Task: <elenco 2.1-2.11>
**Done = <criterio>**

### SPRINT 3 — <NOME> (modello: <X>)
**Obiettivo**: <descrizione>
Task: <elenco 3.1-3.10>
**Done = <criterio>**

### SPRINT 4 — Hardening & Deploy (modello: <X>)
**Obiettivo**: <descrizione>
Task: <elenco 4.1-4.9>
**Done = <criterio>**

## MATRICE MODELLI PER SPRINT

| Sprint | Modello | Ruolo | Perché |
|---|---|---|---|
| 1 | <MODEL_B> | <ruolo> | <motivo> |
| 2 | <MODEL_A> | <ruolo> | <motivo> |
| 3 | <A+B> | <ruolo> | <motivo> |
| 4 | <MODEL_C se serve> | <ruolo> | <motivo> |

## REPORTING (aggiornamento costante)

- Ogni sprint: `STATUS_<sprint>.md` nel workspace con task, problemi, verifiche, costi.
- Watchdog ogni 15 min: stato container + costi/token/cache → messaggio su chat (dedup).
