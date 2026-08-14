from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class DialogueChoice:
    text: str
    response: str
    relation_delta: int = 0
    memory_tag: str | None = None


@dataclass(frozen=True)
class QuestStage:
    title: str
    text: str
    unlock_rifts: int
    choices: tuple[DialogueChoice, ...]


@dataclass(frozen=True)
class PersonalArc:
    arc_id: str
    title: str
    stages: tuple[QuestStage, ...]


@dataclass(frozen=True)
class CompanionTemplate:
    template_id: str
    name: str
    origin: str
    voice: str
    allowed_classes: tuple[str, ...]
    personality_tags: tuple[str, ...]
    base_willingness: int
    min_guild_rank: str
    intro: str
    recruit_success: str
    recruit_fail: str
    farewell: str
    return_line: str
    idle_lines: tuple[str, ...]
    messages: tuple[str, ...]
    camp_lines: tuple[str, ...]
    arcs: tuple[PersonalArc, ...]


def _arc(arc_id: str, title: str, a: tuple[str, str, str], b: tuple[str, str, str]) -> PersonalArc:
    return PersonalArc(
        arc_id,
        title,
        (
            QuestStage(
                a[0], a[1], 0,
                (
                    DialogueChoice("Powiedz mi więcej.", a[2], 3, f"{arc_id}:heard"),
                    DialogueChoice("Nie musisz mówić, jeśli nie chcesz.", "Doceniam to. Może innym razem.", 2, f"{arc_id}:space"),
                ),
            ),
            QuestStage(
                b[0], b[1], 1,
                (
                    DialogueChoice("Zrobimy to razem.", b[2], 4, f"{arc_id}:together"),
                    DialogueChoice("Najpierw upewnijmy się, że to ma sens.", "Rozsądnie. Właśnie dlatego pytam ciebie.", 2, f"{arc_id}:careful"),
                ),
            ),
            QuestStage(
                "Domknięcie",
                "Po kolejnej wspólnej wyprawie temat wraca. Tym razem nie brzmi już jak prośba o pomoc, tylko jak decyzja, którą kompan chce podjąć razem z tobą.",
                2,
                (
                    DialogueChoice("Jestem z tobą do końca.", "Dobrze. W takim razie kończymy to po naszemu.", 5, f"{arc_id}:finished"),
                    DialogueChoice("Zrób to, co uważasz za właściwe.", "Może właśnie tego potrzebowałem: żeby ktoś nie wybierał za mnie.", 4, f"{arc_id}:finished"),
                ),
            ),
        ),
    )


COMPANION_TEMPLATES: dict[str, CompanionTemplate] = {
    "elyra": CompanionTemplate(
        "elyra", "Elyra", "Akademia Arkanów w stolicy",
        "precyzyjna, spokojna, suchy humor",
        ("mage",), ("rational", "scholar", "reserved"), 58, "D",
        "Magini w poplamionym atramentem płaszczu przegląda tablicę kontraktów i poprawia cudze błędy w opisach zaklęć.",
        "Nie myl współpracy z przyjaźnią. Na razie interesuje mnie tylko to, czy potrafisz nie umrzeć w połowie zdania.",
        "Jeszcze nie. Twoje osiągnięcia są interesujące, ale interesujące nie znaczy wystarczające.",
        "Nie mam ci tego za złe. Po prostu następnym razem nie mów, że decyzja była łatwa.",
        "Sądziłam, że zamknęliśmy ten rozdział. Widocznie nie wszystkie rozdziały słuchają autora.",
        (
            "Garran twierdzi, że mój kostur jest 'za delikatny'. Garran wali młotem w metal i nazywa to argumentem.",
            "Pierrot powiedział mi dziś, że prawdopodobieństwo jest opinią. Od godziny próbuję zdecydować, czy to głupota, czy herezja.",
            "Jeśli jeszcze raz zobaczę w raporcie Gildii słowo 'mana' zapisane przez jedno n, zacznę palić dokumenty razem z Koroną.",
        ),
        (
            "Nie chcę alarmować, ale Garran od godziny ogląda twój miecz i mówi do niego 'biedactwo'.",
            "Znalazłam w archiwum przypis o Szczelinach. Ktoś go wyciął nożem. Bardzo subtelne.",
            "Przypominam: dwa zaklęcia w jednej chwili to technika. Trzy to wypadek przy pracy.",
        ),
        (
            "Nie ruszaj mojego kubka. W Szczelinie nawet herbata wygląda podejrzanie.",
            "Jeśli ściany zaczną szeptać, nie odpowiadaj. To nie jest przesąd. To doświadczenie.",
        ),
        (
            _arc("elyra_archive", "Kartoteka, której nie ma", ("Wycięta strona", "Elyra przyznaje, że w Akademii widziała księgę z tym samym symbolem, który pojawia się w raportach o Przebudzeniu.", "Wiedziałam, że to zapamiętałeś."), ("Dawny wykładowca", "Jej były nauczyciel podobno opuścił stolicę tuż po królewskim zakazie handlu księgami.", "Jeśli go znajdziemy, chcę usłyszeć prawdę bez akademickich ozdobników.")),
            _arc("elyra_debt", "Dług wobec wiedzy", ("Nieoddana księga", "Elyra zdradza, że jedna z jej ksiąg nie należała do niej i nigdy nie wróciła do właściciela.", "To nie jest kradzież. To... przedłużone wypożyczenie."), ("Cena ciszy", "Właściciel księgi jest związany z ludźmi handlującymi zakazaną wiedzą.", "Właśnie dlatego nie chciałam wciągać w to nikogo rozsądnego.")),
        ),
    ),
    "kael": CompanionTemplate(
        "kael", "Kael", "pograniczne garnizony", "bezpośredni, ironiczny, lojalny",
        ("warrior",), ("practical", "protective", "dry"), 64, "E",
        "Wojownik siedzi bokiem na ławie, jakby celowo zostawiał sobie widok na wszystkie wyjścia z sali.",
        "Dobra. Ty wybierasz drogę, ja pilnuję, żeby droga nie zjadła reszty drużyny.",
        "Nie obraź się. Widziałem już zbyt wielu bohaterów, którzy byli wielcy tylko przy tablicy ogłoszeń.",
        "Jeśli kiedyś będziesz potrzebował tarczy, wiesz gdzie mnie szukać. O ile nie znajdę rozsądniejszej pracy.",
        "No proszę. Myślałem, że znalazłeś już kogoś lepszego.",
        (
            "Wiesz, co jest najgorsze w ciężkiej zbroi? Każdy uważa, że możesz nosić również jego rzeczy.",
            "Nie mam nic przeciwko Pierrotom. Dopóki nie rzucają kośćmi, żeby zdecydować, kto stoi z przodu.",
            "Najlepsza taktyka? Przeżyć pierwsze dziesięć sekund. Potem przeciwnik zwykle zaczyna popełniać błędy.",
        ),
        (
            "Jeśli planujesz dziś Szczelinę, daj znać wcześniej. Tarcza też ma prawo psychicznie się przygotować.",
            "Mirela twierdzi, że moje rany 'wyglądają interesująco'. Nie wiem, czy powinienem się martwić.",
        ),
        (
            "Ogień jest mały, ale przynajmniej nie próbuje nas zabić. Na razie.",
            "Śpij. Ja pierwszą wartę wezmę bez dyskusji.",
        ),
        (
            _arc("kael_garrison", "Ostatni rozkaz garnizonu", ("Stary znak", "Kael rozpoznaje znak na jednym z raportów jako symbol oddziału, w którym kiedyś służył.", "Nie sądziłem, że zobaczę go jeszcze raz."), ("Lista poległych", "W archiwum brakuje kilku nazwisk ludzi z jego oddziału.", "Jeśli żyją, chcę wiedzieć. Jeśli nie, też chcę wiedzieć.")),
            _arc("kael_oath", "Przysięga bez sztandaru", ("Złamana przysięga", "Kael odszedł z garnizonu, gdy dowódca kazał zostawić cywilów za murem.", "Nie żałuję. To nie znaczy, że dobrze śpię."), ("Świadek", "Ktoś z dawnego garnizonu pojawił się w Varenhold.", "Nie chcę pojedynku. Chcę, żeby ktoś wreszcie powiedział głośno, co się wtedy stało.")),
        ),
    ),
    "nessa": CompanionTemplate(
        "nessa", "Nessa", "Lodowe Wybrzeże", "cicha, złośliwa, obserwuje więcej niż mówi",
        ("hunter",), ("quiet", "observant", "competitive"), 55, "D",
        "Łowczyni stoi przy oknie i obserwuje dziedziniec zamiast ludzi w sali. Jej łuk wygląda na zdecydowanie droższy niż płaszcz.",
        "Nie lubię dużych drużyn. Cztery osoby to jeszcze nie tłum. Spróbujmy.",
        "Za głośno o tobie mówią, a za mało widziałam. Jeszcze nie.",
        "Bez urazy. Po prostu wolę odejść, zanim zaczniemy sobie przeszkadzać.",
        "Myślałam, że już się nauczyłeś, że nie każdy dobry strzelec czeka wiecznie.",
        (
            "Najlepsza strzała to nie ta, która trafia. To ta, po której przeciwnik źle zgaduje, co poleci następne.",
            "Ktoś w Gildii nazwał mój łuk 'ładnym'. Mam nadzieję, że nie planuje go dotykać.",
            "Trzy strzały wystarczą, żeby powiedzieć bardzo dużo. Ludzie zwykle potrzebują znacznie więcej słów.",
        ),
        (
            "Mam nową kombinację. Nie pytaj, czy bezpieczną. To nie jest właściwe pytanie.",
            "Na północy znowu widziano światło pod lodem. Nie wyglądało jak Aurora.",
        ),
        (
            "Jeżeli usłyszysz cięciwę w środku nocy, to ja. Jeżeli dwie — budź wszystkich.",
            "Nie siadaj po lewej stronie ognia. Stamtąd mam najlepszą linię strzału.",
        ),
        (
            _arc("nessa_echo", "Strzała, która wróciła", ("Drugie trafienie", "Nessa opowiada o strzale, który po trafieniu wrócił do niej jako widmowe echo, zanim jeszcze znała tę technikę.", "Nie, nie pomyliłam tego z odbiciem. Strzały nie wracają przez ludzi."), ("Łuk bez właściciela", "Na wybrzeżu znaleziono podobny łuk przy ciele człowieka, którego Nessa znała.", "Chcę zobaczyć to miejsce. Bez świadków z Gildii.")),
            _arc("nessa_rival", "Trzeci strzał", ("Rywalka", "Nessa wspomina strzelczynię, z którą przez lata wymieniała techniki i wyzwania.", "Nigdy nie wygrałam trzy razy z rzędu. Ona też nie."), ("Brak odpowiedzi", "Od miesięcy nie otrzymała od niej żadnego znaku.", "Jeśli po prostu przegrała zakład, będę wściekła. Jeśli coś się stało... bardziej.")),
        ),
    ),
    "mira": CompanionTemplate(
        "mira", "Mira", "wędrowne trupy południa", "chaotyczna, pogodna, czasem nagle poważna",
        ("pierrot",), ("chaotic", "warm", "gambler"), 52, "C",
        "Pierrot obraca monetę na kostkach palców. Moneta ma dwie różne reszki i ani jednego orła.",
        "Dobra! Tylko ustalmy jedną rzecz: kiedy mówię 'mam pomysł', najpierw pytasz, czy plan obejmuje ogień.",
        "Kości mówią nie. Ja też mówię nie. Kości są bardziej uprzejme.",
        "Rozumiem. Tylko oddaj mi te trzy Goldy, które jeszcze nie zdążyłam od ciebie pożyczyć.",
        "Wiedziałam, że zatęsknisz. Rzuciłam monetą. Dwa razy.",
        (
            "Mam dwie wiadomości. Dobra: wygrałam 400 Gold. Zła: to były twoje 600 Gold.",
            "Gdyby Lewiatan połknął drugiego Lewiatana, to mielibyśmy jeden duży problem czy dwa mniejsze w środku?",
            "Elyra twierdzi, że nie da się wyrzucić siódemki na jednej kości. Brak wyobraźni jest smutny.",
        ),
        (
            "Bardzo ważne: nie otwieraj mojej talii. Jedna karta gryzie.",
            "Widziałam dziś kruka, który spojrzał na mnie i odleciał w przeciwną stronę. Mądry kruk.",
            "Mam plan na Szczelinę. Plan ma trzy etapy. Znam jeden.",
        ),
        (
            "Jeżeli jutro obudzimy się w tym samym miejscu, uznaję noc za sukces.",
            "Ktoś chętny w kości? Stawka: pierwsza warta. I nie, nie oszukuję. Dziś.",
        ),
        (
            _arc("mira_deck", "Karta bez numeru", ("Pusta karta", "Mira pokazuje kartę z talii, która była pusta, a dziś pojawił się na niej znak Szczeliny.", "Wczoraj była czysta. Przysięgam na cudze pieniądze."), ("Talia pamięta", "Karta zmienia obraz po każdej wspólnej Szczelinie.", "To pierwszy raz, kiedy talia śledzi mnie zamiast odwrotnie.")),
            _arc("mira_name", "Imię na odwrocie", ("Stare imię", "Na odwrocie jednej z kości wyryto imię, którego Mira nie używa.", "Nie pytaj jeszcze. Sama nie wiem, czy chcę pamiętać."), ("Trupa", "Do Varenhold dotarła wiadomość od jej dawnej trupy.", "Jeśli to pułapka, będzie przynajmniej tematyczna.")),
        ),
    ),
    "dorian": CompanionTemplate(
        "dorian", "Dorian", "Varenhold", "uprzejmy, ambitny, lubi przesadzać",
        ("warrior", "hunter"), ("ambitious", "social", "dramatic"), 61, "E",
        "Młody Poszukiwacz opowiada przy stole historię tak efektownie, że połowa słuchaczy nie zauważa, jak bardzo zmienia szczegóły.",
        "Wiedziałem, że dostrzeżesz potencjał. Nie martw się, ja też go dostrzegłem.",
        "Jeszcze chwila. Chcę dołączyć do drużyny, o której warto potem opowiadać.",
        "Trudno. Będę musiał znaleźć inną legendę, która potrzebuje narratora.",
        "Widzisz? Wiedziałem, że moja nieobecność poprawi twoją ocenę sytuacji.",
        (
            "Nie kłamię. Redaguję wspomnienia, zanim staną się historią.",
            "Jeśli przeżyjemy Szczelinę A, proszę tylko, żeby nikt nie poprawiał mnie przy opowiadaniu wersji karczemnej.",
        ),
        ("Mam nowy tytuł dla naszej drużyny. Nie, jeszcze go nie powiem. Musi dojrzeć.",),
        ("Ognisko potrzebuje historii. Na szczęście jesteście ze mną.",),
        (_arc("dorian_story", "Historia bez bohatera", ("Stary raport", "Dorian odkrywa, że opowieść, na której zbudował własną legendę, należała do zapomnianego Poszukiwacza.", "Nie ukradłem jej. Po prostu... nikt inny jej nie pamiętał."), ("Prawdziwe nazwisko", "W raporcie znajduje się nazwisko człowieka, który nadal żyje.", "Muszę go znaleźć, zanim ktoś inny opowie tę historię źle.")),),
    ),
    "sylvi": CompanionTemplate(
        "sylvi", "Sylvi", "mokradła Głuchej Wody", "cierpliwa, pragmatyczna, makabryczny humor",
        ("mage", "hunter"), ("practical", "morbid", "calm"), 60, "D",
        "Kobieta suszy przy piecu mokre rękawice. Pachną ziołami, błotem i czymś, czego lepiej nie identyfikować.",
        "Może być. Jeśli umrzesz, przynajmniej nie pozwolę, żeby ciało się zmarnowało. Żartuję. Prawie.",
        "Nie teraz. Widziałam, jak ludzie wracają z wypraw, które miały być 'pewne'.",
        "Dbaj o siebie. Naprawdę. To nie był żart.",
        "No proszę. Nadal żyjesz. To znacznie ułatwia rozmowę.",
        ("Mokradła uczą jednej rzeczy: jeśli coś przestało śmierdzieć, prawdopodobnie jest gorzej.",),
        ("Mirela chce przepis na moją maść. Nie dostanie. Jeszcze nie.",),
        ("Nie dotykaj tej butelki. To nie mikstura. To obiad.",),
        (_arc("sylvi_mother", "Pieśń z bagna", ("Znajomy głos", "Sylvi słyszała w Głuchej Wodzie pieśń należącą do osoby, która zaginęła lata temu.", "Na bagnie martwi też potrafią mieć dobrą pamięć."), ("Powrót", "Ślad prowadzi do starego domu poza bezpiecznym traktem.", "Nie idę tam sama. To jedyna rozsądna rzecz, jaką dziś powiem.")),),
    ),
    "orenna": CompanionTemplate(
        "orenna", "Orenna", "górskie klasztory", "surowa, opanowana, zaskakująco opiekuńcza",
        ("warrior", "mage"), ("disciplined", "protective", "spiritual"), 50, "C",
        "Poszukiwaczka siedzi w ciszy przy ścianie. Mimo tłumu wokół niej nikt przypadkiem nie zajmuje sąsiedniego krzesła.",
        "Przyjmuję. Nie oczekuj ode mnie posłuszeństwa. Oczekuj uczciwości.",
        "Twoja siła nie jest problemem. Nie wiem jeszcze, czy masz dyscyplinę, żeby jej nie zmarnować.",
        "Rozstanie też jest decyzją. Uszanuję ją.",
        "Nie sądziłam, że wrócisz do tej decyzji. Dobrze. Ja również ją przemyślałam.",
        ("Cisza nie jest niezręczna. Ludzie po prostu rzadko dają jej szansę.",),
        ("Jeśli planujesz Szczelinę, odpocznij najpierw. Odwaga i zmęczenie brzmią podobnie tylko z daleka.",),
        ("Ogień jest dobry. Przynajmniej mówi wprost, kiedy parzy.",),
        (_arc("orenna_bell", "Dzwon bez klasztoru", ("Dźwięk", "Orenna słyszała w Szczelinie dzwon identyczny jak ten z klasztoru, który opuściła.", "Tamten dzwon stopiono dziesięć lat temu."), ("Pęknięta pieczęć", "W archiwach odnajduje symbol swojego zakonu przy raporcie o dawnej Szczelinie.", "Wygląda na to, że moi nauczyciele przemilczeli znacznie więcej niż sądziłam.")),),
    ),
    "veyn": CompanionTemplate(
        "veyn", "Veyn", "Czarny Bór", "uprzejmy, chłodny, prowokuje pytaniami",
        ("hunter", "pierrot"), ("clever", "secretive", "provocative"), 47, "C",
        "Szczupły Poszukiwacz tasuje karty, choć nie wygląda na Pierrota. Kiedy zauważa twoje spojrzenie, chowa talię bez pośpiechu.",
        "Dobrze. Zobaczymy, czy plotki o tobie są mniej przesadzone niż zwykle.",
        "Nie. Ale jeśli pytasz drugi raz, prawdopodobnie zacząłeś mnie interesować.",
        "To rozsądne. Najgorsze umowy trwają tylko dlatego, że nikt nie chce pierwszy odejść.",
        "Interesujące. Ludzie zwykle wracają po pieniądze, nie po mnie.",
        ("Nie ufam ludziom, którzy mówią, że niczego nie ukrywają. To bardzo ambitne kłamstwo.",),
        ("Ktoś pytał dziś o ciebie na Czarnym Rynku. Nie powiedziałem nic. Jeszcze.",),
        ("Nie zasypiaj pierwszy. To rada, nie groźba.",),
        (_arc("veyn_market", "Cena nazwiska", ("Pytanie bez odpowiedzi", "Veyn przyznaje, że ktoś na Czarnym Rynku płaci za informacje o twojej drużynie.", "Nie sprzedałem. To nie znaczy, że nie chcę wiedzieć, kto kupuje."), ("Pośrednik", "Udaje się ustalić znak używany przez pośrednika.", "Teraz zaczyna być ciekawie. A ciekawość zwykle jest droga.")),),
    ),
    "talia": CompanionTemplate(
        "talia", "Talia", "Popielne Pogranicze", "energiczna, szczera, źle znosi bezczynność",
        ("warrior", "hunter"), ("bold", "impatient", "loyal"), 66, "E",
        "Poszukiwaczka poprawia pas broni i co chwilę zerka na drzwi, jakby samo siedzenie w Gildii było stratą czasu.",
        "Wreszcie. Myślałam, że będziemy tak stać do jutra.",
        "Za wolno. Najpierw pokaż, że potrafisz podjąć decyzję zanim okazja zniknie.",
        "Szkoda. Ale wolę szybkie 'nie' od powolnego 'może'.",
        "No. Tym razem nie każ mi czekać.",
        ("Jeśli plan wymaga trzech godzin dyskusji, to nie plan. To kara.",),
        ("Widziałam nowy alarm Szczeliny. Powiedz tylko kiedy.",),
        ("Kto bierze pierwszą wartę? Odpowiedź 'Talia' nie jest dozwolona.",),
        (_arc("talia_caravan", "Karawana popiołu", ("Pusty wóz", "Talia rozpoznaje opis karawany zaginionej na Popielnym Pograniczu.", "Jechał nią mój brat. Nie powiedziałam wcześniej, bo nie chciałam litości."), ("Ślady", "Nowy raport mówi o znalezionych śladach poza głównym traktem.", "Jeśli to fałszywy trop, trudno. Jeśli prawdziwy, nie wybaczę sobie zwłoki.")),),
    ),
    "cassian": CompanionTemplate(
        "cassian", "Cassian", "stolica", "elegancki, sceptyczny, bardzo kompetentny",
        ("mage",), ("arrogant", "competent", "skeptical"), 42, "B",
        "Mag w nienagannie czystym płaszczu wygląda w Gildii jak człowiek, który pomylił drzwi i postanowił nikomu o tym nie mówić.",
        "Twoje wyniki są wystarczająco dobre, żebym zaryzykował reputację. Nie zmarnuj tej inwestycji.",
        "Nie. Różnica między odwagą a kompetencją jest większa, niż sugerują ballady.",
        "Było... pouczająco. To więcej, niż mówię o większości współpracowników.",
        "Wracasz z lepszą ofertą czy lepszym argumentem?",
        ("W Varenhold wszystko jest albo brudne, albo podejrzane. Czasem jedno i drugie.",),
        ("Przejrzałem twoje raporty ze Szczelin. Masz okropny charakter pisma i irytująco dobre wyniki.",),
        ("Nie chrapię. To rezonans arkaniczny.",),
        (_arc("cassian_crown", "Archiwum Korony", ("Pieczęć", "Cassian rozpoznaje królewską pieczęć na raporcie o zakazanych księgach.", "Mój ojciec podpisywał takie dokumenty."), ("Rodzinny obowiązek", "Rodzina Cassiana nadal pracuje dla Korony i próbuje sprowadzić go do stolicy.", "Nie jestem pewien, czy chcą mojego powrotu, czy mojego milczenia.")),),
    ),
    "lumi": CompanionTemplate(
        "lumi", "Lumi", "nieznane", "łagodna, dziwaczna, mówi rzeczy zbyt trafne",
        ("pierrot", "mage"), ("mysterious", "gentle", "odd"), 44, "B",
        "Dziewczyna siedzi na podłodze pod tablicą Gildii i układa sześć kości w idealnie prostą linię. Żadna nie pokazuje tej samej liczby.",
        "Dobrze. Miałam sen, w którym już się zgodziliśmy, więc to oszczędza czas.",
        "Jeszcze nie. W moim śnie miałeś inną minę.",
        "W porządku. Nie wszystkie drogi muszą kończyć się razem.",
        "Wiedziałam, że wrócisz. Nie pytaj skąd. To psuje efekt.",
        ("Dzisiaj nic dziwnego się nie wydarzyło. To mnie niepokoi.",),
        ("Jeśli zobaczysz w Szczelinie drzwi, których wcześniej nie było, nie otwieraj ich przede mną.",),
        ("Śnił mi się ten ogień. Wtedy był zielony. Wolę ten.",),
        (_arc("lumi_dream", "Sen, który pamięta", ("Powtarzający się sen", "Lumi opisuje Szczelinę, której drużyna jeszcze nie widziała.", "Nie wiem, czy to przyszłość. Przyszłość zwykle gorzej się ubiera."), ("Zgodność", "Kolejna Szczelina zawiera fragment dokładnie taki jak w jej opisie.", "Nie lubię mieć racji w takich sprawach.")),),
    ),
    "brann": CompanionTemplate(
        "brann", "Brann", "porty Czarnego Morza", "gadatliwy, pogodny, skrywa lęk za żartami",
        ("warrior", "hunter"), ("jovial", "fearful", "loyal"), 68, "E",
        "Mężczyzna z marynarskim płaszczem śmieje się z czegoś przy barze, ale za każdym razem, gdy ktoś wspomina Czarną Flotę, przestaje na pół sekundy.",
        "Pewnie! Najwyżej wszyscy zginiemy, a wtedy nikt nie będzie mógł narzekać na decyzję.",
        "Jeszcze nie, przyjacielu. Muszę wiedzieć, czy jesteś typem człowieka, który wraca po swoich.",
        "Bez urazy. Morze nauczyło mnie, że czasem lepiej zejść z pokładu przed sztormem.",
        "Ha! Wiedziałem, że brakowało ci kogoś, kto mówi za dużo.",
        ("Nie boję się duchów. Boję się marynarzy, którzy twierdzą, że nie boją się duchów.",),
        ("Jeśli znów pójdziemy na Wrak, proszę: bez dzwonów.",),
        ("Ktoś ma rum? Nie? Świetnie, to pozostaje nam odwaga. Znacznie gorszy trunek.",),
        (_arc("brann_fleet", "Czwarty dzwon", ("Noc na morzu", "Brann był na statku, który usłyszał cztery dzwony Czarnej Floty, choć według legend powinny być trzy.", "Czwarty zadzwonił pod nami."), ("Lista załogi", "Na Wraku znajduje się nazwisko człowieka z jego dawnej załogi.", "Nie chcę go znaleźć żywego. Boję się, że znajdę go inaczej.")),),
    ),
}


# Ręcznie napisane scenki dla konkretnych par. Losowość wybiera scenę,
# ale sama treść nigdy nie jest generowana w locie.
PAIR_BANTER: dict[frozenset[str], tuple[tuple[str, str], ...]] = {
    frozenset(("elyra", "mira")): (
        ("Elyra: To matematycznie niemożliwe.", "Mira: A jednak wyrzuciłam sześć.\nElyra: Dwoma kośćmi k4."),
        ("Mira: Chcesz nauczyć się oszukiwać kości?", "Elyra: Chcę nauczyć kości przestrzegania praw natury."),
    ),
    frozenset(("kael", "mira")): (
        ("Kael: Nie rzucaj kością, żeby wybrać wartę.", "Mira: Spokojnie. Tym razem rzucam, kto NIE bierze warty."),
    ),
    frozenset(("nessa", "dorian")): (
        ("Dorian: W mojej wersji opowieści ten strzał przeleciał przez trzy cele.", "Nessa: W mojej wersji zamykasz usta po pierwszym."),
    ),
    frozenset(("cassian", "mira")): (
        ("Cassian: Przypadek nie jest metodą.", "Mira: To dziwne, bo metoda właśnie uratowała ci życie."),
    ),
    frozenset(("brann", "elyra")): (
        ("Brann: Magowie zawsze tak patrzą, jakby wiedzieli coś, czego nie wiem?", "Elyra: Nie zawsze. Czasem wiemy kilka rzeczy."),
    ),
    frozenset(("orenna", "talia")): (
        ("Talia: Możemy już iść?", "Orenna: Możemy. Pytanie, czy możemy też wrócić."),
    ),
}

# Pierwsze rozmowy rekrutacyjne są również ręcznie napisane. Interfejs daje
# graczowi trzy stałe intencje rozmowy, ale odpowiedź i wpływ na nastawienie
# zależą od konkretnego człowieka, a nie od generycznego generatora tekstu.
# Kolejność: [współpraca, zwykła rozmowa, najtrudniejsza walka].
CANDIDATE_CONVERSATIONS: dict[str, tuple[tuple[str, int], ...]] = {
    "elyra": (
        ("Elyra odkłada notatki. „Konkretnie. Dobrze. Jeśli mam ryzykować życie z trzema ludźmi, wolę wiedzieć, czy przynajmniej jeden z nich potrafi planować.”", 7),
        ("„Zwyczajna rozmowa?” Elyra unosi brew. „Dobrze. Zacznij od czegoś prostego: dlaczego w Varenhold wszyscy piją coś, co nazywają kawą, a smakuje jak kara?”", 4),
        ("Elyra nie przerywa ani razu. Dopiero na końcu pyta o jedną decyzję, którą sam uznałeś za mało ważną. „Właśnie ta część mnie interesowała.”", 5),
    ),
    "kael": (
        ("Kael kiwa głową. „Dobra odpowiedź. Nie potrzebuję dowódcy, który krzyczy najgłośniej. Potrzebuję kogoś, kto wie, kiedy powiedzieć: wracamy po swojego.”", 7),
        ("„Bez kontraktów? Wreszcie.” Kael przesuwa ci kubek. „Powiedz mi tylko, kto wymyślił ceny w tej karczmie, żebym wiedział, komu nigdy nie ufać.”", 5),
        ("Kael słucha do końca. „Przeżyłeś, więc coś zrobiłeś dobrze. Bardziej interesuje mnie, kogo wtedy nie zostawiłeś z tyłu.”", 6),
    ),
    "nessa": (
        ("Nessa patrzy na ciebie chwilę dłużej. „Jeśli po pierwszym nieudanym planie potrafisz zmienić drugi strzał zamiast obrażać się na świat, możemy się dogadać.”", 6),
        ("„Zwyczajnie?” Wzrusza ramionami. „Dobrze. Nie dotykaj mojego łuku i już mamy wspólny temat, w którym się zgadzamy.”", 3),
        ("Nessa zadaje tylko dwa pytania: gdzie stał przeciwnik i dlaczego nie uciekłeś. Po odpowiedzi lekko się uśmiecha. „Przynajmniej pamiętasz szczegóły.”", 7),
    ),
    "mira": (
        ("Mira wyciąga kość. „Zasady drużyny? Świetnie. Ja mam jedną: jeśli mówię »uciekaj«, nie pytasz dlaczego. Jeśli mówię »mam pomysł« — wtedy pytasz koniecznie.”", 5),
        ("„O! Człowiek, który nie zaczyna rozmowy od liczby zabitych potworów.” Mira natychmiast ożywa. „Dobra, najważniejsze: słodkie czy słone śniadanie?”", 8),
        ("Mira słucha z zaskakującą uwagą. „Czyli postawiłeś wszystko na jedną decyzję i przeżyłeś? To nie jest rozsądne. Podoba mi się.”", 7),
    ),
    "dorian": (
        ("Dorian uśmiecha się szeroko. „Współpraca, jasne. Ja robię rzeczy efektowne, ty potem w raporcie piszesz, że były przemyślane.”", 5),
        ("„Wreszcie normalny temat. Słyszałeś historię o człowieku, który próbował oszukać Orena na wadze? Nie? To usiądź.”", 7),
        ("Dorian wysłuchuje opowieści i natychmiast proponuje trzy sposoby, jak można ją opowiadać lepiej. Pod czwartym żartem widać jednak, że jest pod wrażeniem.", 5),
    ),
    "sylvi": (
        ("Sylvi poprawia rękawice. „Moje oczekiwanie jest proste: jeśli ktoś krwawi, mówi o tym zanim zacznie widzieć dwie wersje mnie.”", 7),
        ("„Bez pracy? Dobrze.” Uśmiecha się lekko. „Jak bardzo przeszkadza ci rozmowa o pasożytach przy jedzeniu?”", 6),
        ("Sylvi zamiast pytać o bossa pyta, jak wyglądały rany po walce. „Nie patrz tak. To dużo mówi o tym, czy człowiek wie, kiedy się wycofać.”", 5),
    ),
    "orenna": (
        ("Orenna słucha w ciszy. „Nie oczekuję, że zawsze wybierzesz dobrze. Oczekuję, że będziesz umiał ponieść koszt własnego wyboru.”", 7),
        ("„Możemy milczeć przez chwilę.” Po dłuższej ciszy dodaje: „To też jest rozmowa. Zaskakująco niewielu ludzi to rozumie.”", 5),
        ("Orenna nie komentuje twojej siły. „Co zrobiłeś po zwycięstwie?” Dopiero odpowiedź na to pytanie wydaje się ją naprawdę interesować.", 6),
    ),
    "veyn": (
        ("Veyn splata dłonie. „Czego oczekuję? Żebyś nie mylił zaufania z dostępem do wszystkich moich sekretów. Jeśli to akceptujesz, zaczynamy dobrze.”", 6),
        ("„Zwyczajna rozmowa bywa bardziej niebezpieczna niż przesłuchanie.” Uśmiecha się. „Ludzie wtedy zapominają pilnować odpowiedzi.”", 5),
        ("Veyn wypytuje nie o zwycięstwo, lecz o moment, w którym prawie przegrałeś. „Dobrze. Ludzie, którzy pamiętają własny strach, są mniej przewidywalni.”", 7),
    ),
    "talia": (
        ("Talia odpowiada zanim skończysz. „Tak. Ruch, decyzja, odpowiedzialność. Jeśli coś pójdzie źle, poprawiamy w biegu, a nie robimy narady przez pół dnia.”", 8),
        ("„Pogadać? Możemy gadać idąc.” Kiedy orientuje się, że nigdzie nie idziecie, wzdycha teatralnie. „Dobra. Pięć minut.”", 4),
        ("Talia nachyla się nad stołem. „I wtedy naprawdę zostałeś? Dobra. To akurat było głupie. Ale takie głupie, które czasem chcę mieć obok siebie.”", 7),
    ),
    "cassian": (
        ("Cassian poprawia mankiet. „Oczekiwania są mało istotne. Interesują mnie standardy. Jeśli twoim standardem jest »jakoś to będzie«, oszczędźmy sobie czasu.”", 5),
        ("„Rozmowa bez celu jest luksusem.” Milknie. „...ale tutejsze wino jest tak złe, że krytykowanie go można uznać za obowiązek obywatelski.”", 3),
        ("Cassian wyłapuje każdą nieścisłość. Gdy kończysz, mówi tylko: „Nie upiększyłeś własnego błędu. To rzadsze niż talent magiczny.”", 8),
    ),
    "lumi": (
        ("Lumi patrzy gdzieś za twoje ramię. „W twojej drużynie będzie głośno. To dobrze. W cichych drużynach częściej słychać rzeczy, których nie powinno być.”", 6),
        ("„Możemy pogadać o czymś zwyczajnym.” Zastanawia się. „Czy sny o cudzych wspomnieniach liczą się jako zwyczajne?”", 7),
        ("Lumi zna zakończenie twojej historii sekundę przed tobą i marszczy brwi. „Dobrze. Tym razem wydarzyło się tak samo.”", 6),
    ),
    "brann": (
        ("Brann uderza dłonią w stół. „Jedna zasada: wracamy po swoich. Druga: jeśli pierwsza zawiedzie, nie udajemy potem, że to była strategia.”", 8),
        ("„Bez roboty? Świetnie! Mogę ci opowiedzieć, dlaczego nigdy nie grasz w karty z kapitanem, który ma tylko jedną rękę, ale pięć asów.”", 7),
        ("Brann żartuje przez pierwszą połowę opowieści. Przy najgorszym momencie przestaje. „Tak. Znam ten rodzaj ciszy po walce.”", 6),
    ),
}
