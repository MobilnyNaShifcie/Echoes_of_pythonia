# v0.24.3 — Spójność nazewnictwa wyposażenia

Hotfix porządkuje nazwy bez zmiany mechaniki i bez migracji save schema.

- `captain_signet`: **Bransoleta Czarnej Floty** (`bracelet`),
- `storm_archive_relic`: **Medalion Burzowego Archiwum** (`necklace`).

Wewnętrzne identyfikatory pozostają niezmienione, dzięki czemu stare egzemplarze zachowują ulepszenia, affixy i `instance_id`. Dodano test semantyczny dla oczywistych nazw slotów, aby podobne pomyłki nie wracały przy rozbudowie puli wyposażenia.
