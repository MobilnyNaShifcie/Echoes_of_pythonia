# Item Progression + Signature Dungeon Weapons — v0.18.0

## Trzy niezależne poziomy przedmiotu

1. `upgrade_level` — +0..+10, ulepszany u kowala.
2. `item_power` — skala bazowych statystyk i affixów T1-T5.
3. `required_level` — minimalny poziom postaci potrzebny do założenia.

Dzięki temu przyszły sprzęt może mieć wyższy Item Power bez wymuszania
sztywnego powiązania z jednym konkretnym poziomem postaci.

## Obecne wymagania

- Start: 0.
- Zmierzchowe Równiny: 1-3.
- Czarny Bór: 3-5.
- Mokradła Głuchej Wody: 5-8.
- Krypta Zatopionego Zakonu: 10.

Zdobycie/crafting przedmiotu ponad poziom gracza jest dozwolone. Ograniczenie
dotyczy wyłącznie jego założenia.

## Signature Dungeon Weapon

Pierwsza specjalna broń:
`grandmaster_sword` — Miecz Wielkiego Mistrza.

Źródło:
- boss: Wielki Mistrz Zatopionego Zakonu,
- bezpośredni drop: 12%,
- crafting z materiałów Krypty jako bad-luck protection.

## Średnie Obrażenia

Każda instancja Miecza Wielkiego Mistrza losuje integer od -5% do +15%.
Roll nie jest affixem i nie zmniejsza liczby bonusów wynikającej z rarity.

Kolejność dla zwykłego uderzenia:
1. ATK / mnożnik ataku,
2. DEF / odporności przeciwnika,
3. Średnie Obrażenia,
4. bonus sytuacyjny vs Elite/Boss,
5. trafienie krytyczne.

Średnie Obrażenia nie są nakładane na aktywne umiejętności. Umiejętności
mają osobną statystykę `Skill Damage`.

## Migracja v8 → v9

Istniejący Miecz Wielkiego Mistrza otrzymuje roll deterministyczny na podstawie
`item_id + instance_id`. Affixy v0.17 nie są przy tym ponownie losowane.
Po pierwszym zapisie v0.18 wartość jest przechowywana w save jako
`average_damage_percent`.
