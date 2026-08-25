# CONTEXT — <PROJECT_NAME>

> **Mandatory use**: read this file AT THE START of every session and keep it
> STABLE in the context (never rewrite it mid-conversation) to maximize the
> provider's CACHE HITS 

## 1. MISSION
<Describe the project in 2-3 sentences: what it builds, for whom, main constraints.>

## 2. CACHE-HIT RULES (ALWAYS — non-negotiable)
1. Stable context at the top: system prompt + this file + data schema = first blocks.
2. Dynamic data (changing values) ALWAYS goes after the static blocks.
3. Read the files ONCE per session; do not reload them every turn.
4. Never raw dumps: only aggregates, never 60KB of JSON in the context.
5. Long sessions: never restart the container mid-task (the cache dies).
6. Never paste whole scripts/files into the context: summarize + cite the path.

## 3. STACK
- Languages/frameworks: <...>
- Backend/data source: <host, endpoint, DB>
- Transport/network: <ZeroTier, LAN, VPN...>
- Key libraries: <...>

## 4. SECTIONS / MODULES (if applicable)
1. <Module A> — <description>
2. <Module B> — <description>

## 5. DATA ACCESS RULES
- Databases: READ-ONLY (WAL mode). Never write to production data.
- Credentials: only those explicitly documented here; never guess or invent them.
- Sources: verify reachability before use; if unreachable, document the block.
