# app/ — Ô Forneau ! (Flutter)

App mobile iOS+Android. Fondations Phase 0 posées ; les **features MVP** (recherche à facettes, « dans mon
frigo », fiche + mode cuisine, portions, favoris, liste de courses, historique) arrivent en **Phase 2**,
une fois la **Phase 1 acquise** (≥ 300 recettes `published`). Aujourd'hui : 39 recettes en `review`, 0 publiée.

## Stack (tranchée)
Flutter 3.35 · Riverpod (codegen à activer avec les features) · go_router · google_fonts (Fraunces/Inter).
À venir avec les features : `supabase_flutter` (clé publique anon uniquement, jamais la clé service), cache
offline **Drift** ou **Isar** (à trancher et documenter ICI avant la 1re écriture de cache ; défaut pressenti
Drift, schéma proche du Postgres).

## Architecture (skill forneau-app-flutter)
```
lib/core/     theme (export design-system), router (go_router), l10n, errors
lib/data/     client Supabase, repositories, mappers DTO↔domaine, cache local   (Phase 2)
lib/domain/   entités Recipe/Ingredient/Appliance/Diet/Pantry/CookStep, use cases (Phase 2)
lib/features/ <feature>/ (presentation + providers Riverpod)                     (Phase 2)
lib/l10n/     app_fr.arb (FR natif d'abord)                                      (Phase 2)
```

## Règles non négociables portées côté app
- `source_url`/`source_platform` ni mappés ni affichés (règle légale §2.3) — pas même sélectionnés dans les requêtes.
- Aucun nom de chef, aucune image Instagram, même en cache/fixture.
- Offline-first sur recettes vues + favoris. FR natif, aucun string en dur hors l10n. Cibles 48 dp, AA.
- Clés publiques via `--dart-define`, jamais commitées.

## Lancer
`cd app && ~/flutter/bin/flutter pub get && ~/flutter/bin/flutter analyze` (propre au 2026-11-08).
