# v0.22.0 — Guild & Black Market

## Rangi Gildii

| Ranga | Nazwa | Reputacja | Główne odblokowanie |
|---|---|---:|---|
| F | Nowicjusz | 0 | podstawowe zadania |
| E | Adept | 100 | kontrakty dzienne |
| D | Poszukiwacz | 300 | kontrakt tygodniowy |
| C | Łowca | 700 | możliwość spotkania informatora po ukończeniu dungeonu |
| B | Weteran | 1400 | wysoka ranga Gildii |
| A | Mistrz | 2600 | najwyższa normalna ranga przed Legendą |
| S | Legenda | 4500 | prestiżowy tytuł `Weteran Gildii` |

Reputacja pochodzi z jednorazowych zadań fabularnych (+50), Daily (+15), Weekly (+75) oraz jednorazowych kamieni milowych świata: Azhar (+100), Lewiatan Północy (+150), Krypta Zatopionego Zakonu (+150), Wrak Czarnej Floty (+250). Powtarzanie tego samego kamienia milowego nie daje ponownie reputacji.

## Informator

Warunki: ranga C lub wyższa oraz ukończona Krypta albo Wrak Czarnej Floty. Przy kwalifikującej wizycie w Karczmie gra wykonuje jedną próbę na nowy dzień Pythonii. Szansa wynosi 20%; po czterech nieudanych dniach piąta próba jest gwarantowana. Ponowne wchodzenie do Karczmy tego samego dnia nie rerolluje spotkania.

Informator nie handluje. Po rozmowie permanentnie odblokowuje lokację `Czarny Rynek`.

## Czarny Rynek

- 4 oferty na rotację,
- rotacja co 3 realne dni,
- restart gry nie zmienia obecnego towaru,
- 55% szansy, że rotacja zawiera jedną Księgę Mistrzostwa,
- reszta to wybrane rzadkie materiały i consumable,
- oferta jest jednosztukowa/jednorazowa w obrębie rotacji,
- książki można również sprzedawać.

### Targowanie

Jedna próba na konkretną ofertę lub tytuł sprzedawanej księgi w danej rotacji. Bazowa szansa sukcesu: 30%.

- zakup: sukces obniża cenę o 10–15%, porażka podnosi ją o 5–10%,
- sprzedaż: sukces podnosi ofertę o 10–15%, porażka obniża ją o 5–10%,
- wynik zostaje zapisany natychmiast, więc restart nie daje kolejnej próby.

## Księgi Mistrzostwa

1. Traktat Mistrzowskiej Regeneracji — Regeneracja Zdrowia 6–10.
2. Manuskrypt Szybkiego Ostrza — Szybkość Ataku 6–10.
3. Kodeks Krytycznego Uderzenia — Obrażenia Krytyczne 6–10.
4. Traktat Siły — Zwiększenie Ataku 6–10.

Przeczytanie zużywa księgę i permanentnie podnosi limit wskazanej pasywki z 5 do 10. Duplikaty pozostają pełnoprawnym lootem i można je zachować lub sprzedać na Czarnym Rynku.

### Drop

Boss nie określa rodzaju księgi. Najpierw losowana jest szansa na dowolną Księgę Mistrzostwa, a po sukcesie jeden z czterech tytułów jest wybierany losowo ze wspólnej puli.

- Azhar / Lewiatan Północy: 1%,
- Strażnik Krypty / Pierwszy Oficer Czarnej Floty: 2%,
- Wielki Mistrz Zatopionego Zakonu / Admirał Varek: 4%.

Zwykłe potwory oraz overworldowi minibossowie nie dropią Ksiąg Mistrzostwa. Pogoda nie zwiększa tych szans.

## Księgi Ścieżki

`Księga Ścieżki` jest osobnym typem danych od `Księgi Mistrzostwa`. v0.22 nie dodaje jeszcze żadnej dostępnej Księgi Ścieżki; zostaną wykorzystane w Classes 2.0 jako rzadkie odblokowania specjalnych gałęzi drzew klasowych.

## Save

Schema v12 zapisuje reputację/rangi przez wartość reputacji, permanentne kamienie milowe, odblokowane Mistrzostwa, informatora, odblokowanie rynku, rotację, wykupione oferty oraz wynegocjowane ceny. Migracja z v11 odbudowuje tylko progres, który da się potwierdzić z trwałych danych starego save. Historycznych odebranych Daily/Weekly sprzed v0.22 nie da się wiarygodnie odtworzyć, ponieważ wcześniej nie były przechowywane jako historia reputacji.


## Aktualizacja v0.23.1

Od v0.23.1 bieżąca zasada rotacji została skrócona z 3 realnych dni do **1 realnego dnia**. Pozostałe zasady Czarnego Rynku pozostają bez zmian.
