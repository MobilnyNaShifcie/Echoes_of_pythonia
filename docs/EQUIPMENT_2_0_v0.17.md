# Equipment 2.0 — v0.17.0

## Cel

v0.17.0 przebudowuje wyposażenie tak, aby obecny terminal był jedynie warstwą prezentacji, a dane przedmiotów nadawały się później bez zmian do pełnego GUI.

## Role slotów

### Defensywne
- Hełm
- Zbroja
- Rękawice
- Buty

Bazowe statystyki i losowe affixy tych slotów dotyczą przeżywalności: DEF, HP, Uniku, regeneracji HP i odporności żywiołowych.

### Ofensywne
- Broń
- Naszyjnik
- Bransoleta
- Kolczyki
- Pierścień

Bazowe statystyki i losowe affixy tych slotów dotyczą obrażeń: ATK, Many, krytyków, Skill Damage, penetracji oraz bonusów przeciw elitom/bossom.

### Mieszany
- Pas

Pas może losować affixy z obu pul, ale wartość rolla jest mnożona przez 0.75. Dzięki temu pas służy do uzupełniania buildu, ale nie zastępuje wyspecjalizowanych slotów.

## Liczba bonusów według rarity

- Zwykły: 0
- Niezwykły: 1
- Rzadki: 2
- Epicki: 3
- Legendarny: 4
- Mityczny: 4 losowe bonusy; specjalny efekt jest zarezerwowany dla późniejszego systemu unikatów

Na jednej instancji nie może powtórzyć się ten sam affix.

## Item Power

Rarity i Item Power są niezależne.

- rarity = liczba losowych bonusów,
- Item Power = skala liczb, które mogą wylosować bonusy.

Obecna zawartość:
- IP I — Zmierzchowe Równiny / początek gry,
- IP II — Czarny Bór,
- IP III — Mokradła Głuchej Wody,
- IP IV — Krypta Zatopionego Zakonu.

## T1–T5

Tier jest jakością pojedynczego rolla:
- T1 = 20% wartości T5,
- T2 = 40%,
- T3 = 60%,
- T4 = 80%,
- T5 = 100%.

W niskim Item Power płaskie wartości całkowite mogą po zaokrągleniu czasem dawać tę samą liczbę na dwóch sąsiednich tierach. W późnym endgame różnice automatycznie stają się bardzo duże.

## Obecne maksymalne wartości T5

| Affix | IP I | IP II | IP III | IP IV |
|---|---:|---:|---:|---:|
| HP | 12 | 18 | 24 | 30 |
| ATK | 2 | 3 | 4 | 5 |
| DEF | 2 | 2 | 3 | 4 |
| Mana | 6 | 8 | 10 | 12 |
| Unik | 1.5% | 2.0% | 2.5% | 3.0% |
| Crit Chance | 2.5% | 3.0% | 3.5% | 4.0% |
| Crit Damage | 8% | 10% | 12% | 15% |
| Skill Damage | 3% | 4% | 5% | 6% |
| Penetracja | 2% | 3% | 4% | 5% |
| Damage vs Elite | 5% | 6% | 8% | 10% |
| Damage vs Boss | 5% | 6% | 8% | 10% |
| Pojedyncza odporność | 5% | 6% | 7% | 8% |

## Skalowanie przyszłego endgame

Płaskie statystyki po IP IV korzystają z krzywej wzrostu x1.75 na każdy kolejny Item Power. To pozwala tej samej mechanice obsługiwać przyszłe regiony z tysiącami HP i setkami ATK.

Przykład: T5 Max HP przy IP XII przekracza 2500 HP, a T1 pozostaje około pięć razy słabszy.

Procenty nie korzystają z tej krzywej. Rosną wolno do twardych limitów:
- Unik: 5%,
- Crit Chance: 10%,
- Crit Damage: 30%,
- Skill Damage: 12%,
- Penetracja: 10%,
- odporność jednego affixu: 15%,
- Damage vs Elite/Boss: 20%.

Dzięki temu przyszłe płaskie statystyki mogą rosnąć bardzo mocno bez multiplikatywnej eksplozji obrażeń.

## Jakość źródła dropu

Rarity konkretnego przedmiotu nadal wynika z jego definicji. Źródło dropu wpływa natomiast na jakość T1–T5:

- zwykły drop: głównie T1–T2,
- elita: lepszy rozkład,
- miniboss: jeszcze lepszy,
- Krypta: premiumowy rozkład tierów,
- boss: najwyższa szansa T4–T5, ale bez gwarantowanego perfekcyjnego rolla.

## Affixy realnie używane przez walkę

v0.17.0 nie przechowuje bonusów jako tekstu. Mechanika walki korzysta z nich bezpośrednio:
- Crit Chance może odblokować krytyk nawet bez pasywki,
- Crit Damage zwiększa mnożnik krytyka,
- Skill Damage zwiększa obrażenia aktywnych umiejętności,
- penetracja procentowo obniża efektywny DEF celu,
- Damage vs Elite działa przeciw elitom,
- Damage vs Boss działa przeciw minibossom i bossom,
- regeneracja HP działa po turze przeciwnika,
- odporności trafiają do istniejącego systemu żywiołów.

## Terminal i przyszłe GUI

Lista plecaka pokazuje tylko wersję kompaktową:

`Miecz +3 [Epicki | IP III | Ofensywny | Bonusy: 3]`

Pełny ekran szczegółów przechowuje i prezentuje dane strukturalnie:

- `affix_id`,
- `tier`,
- `value`,
- `item_power`.

Core gry nie potrzebuje wiedzieć, czy przedmiot pokazuje terminal czy przyszłe GUI.

## Migracja save

Schema v7 → v8.

Przedmiot istniejący przed v0.17 otrzymuje affixy jednorazowo podczas migracji. Losowanie jest deterministyczne na podstawie `instance_id`, więc ponowne wczytanie starego save'a nie zmienia rolla.

Po zapisaniu gry v0.17 Item Power i wszystkie affixy są przechowywane bezpośrednio w save.
