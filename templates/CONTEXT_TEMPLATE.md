# CONTEXT — <PROJECT_NAME>

> **Uso obbligatorio**: questo file va letto ALL'INIZIO di ogni sessione e va
> mantenuto STABILE nel contesto (mai riscritto a metà conversazione) per
> massimizzare i CACHE HIT del provider (cache-read ≈ $0.004/M vs $0.44/M).

## 1. MISSIONE
<Descrivi il progetto in 2-3 frasi: cosa costruisce, per chi, vincoli principali.>

## 2. REGOLE CACHE-HIT (SEMPRE — non negoziabile)
1. Contesto stabile in testa: system prompt + questo file + schema dati = primi blocchi.
2. Dati dinamici (valori che cambiano) SEMPRE dopo i blocchi statici.
3. Leggi i file UNA volta per sessione; non riscaricarli a ogni turno.
4. Mai dump grezzi: solo aggregati, mai 60KB di JSON nel contesto.
5. Sessioni lunghe: non riavviare il container a metà task (la cache muore).
6. Non incollare mai script/file interi nel contesto: riassumi + cita il percorso.

## 3. STACK
- Linguaggi/framework: <...>
- Backend/sorgente dati: <host, endpoint, DB>
- Trasporto/rete: <ZeroTier, LAN, VPN...>
- Librerie chiave: <...>

## 4. SEZIONI / MODULI (se applicabile)
1. <Modulo A> — <descrizione>
2. <Modulo B> — <descrizione>

## 5. MAPPA SCRIPT/SERVIZI → MODULI (riusare, NON riscrivere)
| Script/Servizio | Output | Modulo |
|---|---|---|

## 6. DESIGN SYSTEM / CONVENZIONI
- Palette: <colori esadecimali + significato>
- Tipografia: <...>
- Vincoli visivi: <contrasto, dimensione font...>

## 7. RIFERIMENTI (da emulare / da evitare)
- <App o pattern di riferimento>
- <Errori noti da non ripetere>

## 8. DATI DI ESEMPIO (per test — reali anonimizzati, non inventare)
- <valori campione>

## 9. COSTI E MODELLI
- Orchestratore: <model> ($prezzi)
- Subagente: <model> ($prezzi, cache)
- Budget totale stimato: <€>
- SEMPRE: contesto stabile → cache hit → costo minimo

## 10. VINCOLI
- MAI chiavi API nel codice.
- MAI modificare dati di produzione in scrittura.
- MAI esporre servizi su Internet (solo LAN/VPN).
- MAI inventare dati: se una fonte non risponde, documenta il blocco.
- Ogni implementazione va TESTATA prima di dichiararla done.
