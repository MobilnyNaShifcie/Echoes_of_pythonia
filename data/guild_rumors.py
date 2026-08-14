from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class GuildRumor:
    text: str
    min_rank: str = "F"
    requires_market: bool = False
    requires_milestone: str | None = None


GUILD_RUMORS: tuple[GuildRumor, ...] = (
    GuildRumor("Na Zmierzchowych Równinach znowu znaleziono stracha na wróble, który stał kilka kroków dalej niż poprzedniego dnia. Nikt nie chce sprawdzać, czy jutro podejdzie jeszcze bliżej."),
    GuildRumor("Garran twierdzi, że dobra stal śpiewa pod młotem. Wczoraj jedna podobno odpowiedziała mu szeptem. Od tamtej pory kuźnia zamyka się wcześniej."),
    GuildRumor("Ktoś przyniósł do Gildii mapę z zaznaczoną drogą przez Czarny Bór. Problem w tym, że ścieżka na pergaminie zmienia położenie każdej nocy."),
    GuildRumor("Mirela kupuje składniki, o które rozsądny człowiek nie pyta. Jeśli mikstura zaczyna mrugać, podobno dolicza podwójną cenę."),
    GuildRumor("Marynarze z północy mówią, że przy bezwietrznej nocy spod lodu słychać dzwony okrętowe. Nikt rozsądny nie wypływa wtedy z portu.", "E"),
    GuildRumor("Na Popielnym Pograniczu zaginęła karawana. Konie, wozy i skrzynie znaleziono nietknięte. Brakowało tylko ludzi i wszystkich naczyń z wodą.", "E"),
    GuildRumor("Królestwo objęło stare księgi bojowe zakazem handlu. Oficjalnie chodzi o bezpieczeństwo. Nieoficjalnie nikt na sali nie wierzy, że Korona boi się papieru.", "D"),
    GuildRumor("Strażnicy spalili przed zachodnią bramą cały wóz zakazanych ksiąg. Dziwne tylko, że woźnica wrócił wieczorem z cięższą sakiewką niż rano.", "D"),
    GuildRumor("Mówią, że jedna przeczytana strona Księgi Ścieżki potrafi zmienić sposób walki człowieka bardziej niż dziesięć lat treningu. Nic dziwnego, że Korona chce mieć je pod kluczem.", "C"),
    GuildRumor("Czarny Rynek? Bajki dla naiwnych. Tak przynajmniej powiedział najemnik, który chwilę później kupił mapę pod stołem.", "C"),
    GuildRumor("Jeśli ktoś w karczmie zapyta, czy szukasz wiedzy, której nie ma w bibliotekach, najpierw sprawdź, czy nie ma królewskiego sygnetu pod rękawem.", "C"),
    GuildRumor("Podobno istnieją handlarze, którzy za jedną Księgę Ścieżki żądają więcej Golda niż kosztuje mały dom. Najgorsze, że podobno znajdują kupców.", "C", True),
    GuildRumor("Na Czarnym Rynku nie negocjuje się dwa razy. Pierwsza cena jest obrazą, druga próbą, a trzeciej podobno już nie słyszysz.", "C", True),
    GuildRumor("Nie wszystkie statki Czarnej Floty zatonęły. Niektóre po prostu przestały potrzebować żywej załogi.", "C", requires_milestone="dungeon:black_fleet_wreck"),
    GuildRumor("Ktoś przysięga, że Admirał Varek wydał ostatni rozkaz długo po własnej śmierci. Gildia oficjalnie nie komentuje takich opowieści.", "B", requires_milestone="dungeon:black_fleet_wreck"),
    GuildRumor("W archiwach Gildii istnieją kontrakty, których Nowicjusz nigdy nie zobaczy. Nie dlatego, że są trudne. Dlatego, że niektórych zleceniodawców oficjalnie nie ma.", "B"),
    GuildRumor("Królestwo płaci za konfiskowane księgi, ale jeszcze więcej płaci za nazwiska tych, którzy potrafią je czytać. Ciekawe, czego bardziej się boją.", "B"),
    GuildRumor("Podobno żył Wojownik tak ciężko opancerzony, że przeciwnicy przestali próbować go zranić. Wtedy nauczył się ich prowokować.", "B"),
    GuildRumor("Wędrowny błazen miał pokonać trzech bandytów lancą i parą kości. Świadkowie nie są zgodni, czy miał niewiarygodne szczęście, czy po prostu oszukiwał rzeczywistość.", "B"),
    GuildRumor("Łowcy z dalekiego wschodu opowiadają o strzelcach, których strzały zostawiają po sobie widmowe echa. Trzeci strzał podobno nigdy nie jest tylko trzecim strzałem.", "B"),
    GuildRumor("W starej wieży znaleziono ślady po dwóch zaklęciach rzuconych w tej samej chwili przez jednego maga. Akademia nazwała raport niemożliwym i natychmiast go utajniła.", "A"),
    GuildRumor("Najstarsi Mistrzowie mówią, że Księgi Mistrzostwa są tylko wstępem. Prawdziwie zakazana wiedza nie wzmacnia techniki — ona zmienia zasady, według których technika działa.", "A"),
    GuildRumor("Na północ od znanych map podobno stoją ruiny miasta, którego nazwy nie ma w żadnym królewskim rejestrze. Gildia płaci za każdą wiarygodną wzmiankę.", "S"),
    GuildRumor("Legenda Gildii nie pyta, czy plotka jest prawdziwa. Pyta, ile osób zginęło, próbując ją sprawdzić.", "S"),
    GuildRumor("Na Równinach podobno widziano całe stado wilków uciekające przed czymś, czego nikt później nie znalazł. Zwykle to ludzie uciekają przed wilkami.", "F"),
    GuildRumor("Skrybowie z archiwum zamówili ostatnio więcej zamków niż pergaminu. Ktoś najwyraźniej bardziej boi się czytających niż złodziei.", "E"),
    GuildRumor("W Czarnym Borze wycinano kiedyś znak w korze drzew, żeby coś trzymać z dala od traktu. Dzisiaj te same znaki pojawiają się po wewnętrznej stronie pni.", "D"),
    GuildRumor("Podobno królewski edykt nie zakazuje czytania Ksiąg. Zakazuje ich sprzedaży, przewozu, kopiowania, wypożyczania i 'przypadkowego znalezienia'. Bardzo wygodne.", "D"),
    GuildRumor("Jeden z archiwistów Gildii mówi, że stare pieczęcie nie wyglądały jak symbole kultów. Bardziej jak zamki. Tylko nikt nie wie, co miały zamykać.", "C"),
    GuildRumor("Na Pustkowiach popiół podobno układa się w ten sam wzór, który widziano na kamieniach Głuchej Wody. Przypadek robi się coraz mniej przekonujący.", "C"),
    GuildRumor("Korona wysłała do Gildii trzech urzędników po raporty o przebudzeniach. Wrócili z pustymi rękami. Gildia twierdzi, że dokumenty gdzieś się zapodziały.", "B"),
    GuildRumor("Niektórzy Mistrzowie sądzą, że Aurora nie wzmacnia potworów. Ona tylko pozwala im przypomnieć sobie, czym były wcześniej.", "A"),
)

_RANK_ORDER = {code: index for index, code in enumerate(("F", "E", "D", "C", "B", "A", "S"))}


def available_guild_rumors(rank_code: str, *, market_unlocked: bool, milestones: set[str]) -> list[GuildRumor]:
    rank_index = _RANK_ORDER.get(rank_code, 0)
    return [
        rumor
        for rumor in GUILD_RUMORS
        if _RANK_ORDER[rumor.min_rank] <= rank_index
        and (not rumor.requires_market or market_unlocked)
        and (rumor.requires_milestone is None or rumor.requires_milestone in milestones)
    ]
