class_name CompanionStoryCatalog
extends RefCounted

# gdlint: disable=max-line-length

const DialogueChoiceClass := preload("res://core/companions/companion_dialogue_choice.gd")
const PersonalArcClass := preload("res://core/companions/companion_personal_arc.gd")
const QuestStageClass := preload("res://core/companions/companion_quest_stage.gd")
const StoryDefinitionClass := preload("res://core/companions/companion_story_definition.gd")

const TALK_PROMPTS := [
	"Powiedz wprost, czego oczekujesz od drużyny.",
	"Pogadaj zwyczajnie, bez kontraktów i rang.",
	"Opowiedz o najtrudniejszej walce, jaką masz za sobą.",
]

static var _stories := {
	"elyra":
	_story(
		"elyra",
		"Magini w poplamionym atramentem płaszczu przegląda tablicę kontraktów i poprawia cudze błędy w opisach zaklęć.",
		"Nie myl współpracy z przyjaźnią. Na razie interesuje mnie tylko to, czy potrafisz nie umrzeć w połowie zdania.",
		"Jeszcze nie. Twoje osiągnięcia są interesujące, ale interesujące nie znaczy wystarczające.",
		"Nie mam ci tego za złe. Po prostu następnym razem nie mów, że decyzja była łatwa.",
		"Sądziłam, że zamknęliśmy ten rozdział. Widocznie nie wszystkie rozdziały słuchają autora.",
		[
			"Garran twierdzi, że mój kostur jest 'za delikatny'. Garran wali młotem w metal i nazywa to argumentem.",
			"Pierrot powiedział mi dziś, że prawdopodobieństwo jest opinią. Od godziny próbuję zdecydować, czy to głupota, czy herezja.",
			"Jeśli jeszcze raz zobaczę w raporcie Gildii słowo 'mana' zapisane przez jedno n, zacznę palić dokumenty razem z Koroną.",
		],
		[
			"Nie chcę alarmować, ale Garran od godziny ogląda twój miecz i mówi do niego 'biedactwo'.",
			"Znalazłam w archiwum przypis o Szczelinach. Ktoś go wyciął nożem. Bardzo subtelne.",
			"Przypominam: dwa zaklęcia w jednej chwili to technika. Trzy to wypadek przy pracy.",
		],
		[
			"Nie ruszaj mojego kubka. W Szczelinie nawet herbata wygląda podejrzanie.",
			"Jeśli ściany zaczną szeptać, nie odpowiadaj. To nie jest przesąd. To doświadczenie.",
		],
		[
			_arc(
				"elyra_archive",
				"Kartoteka, której nie ma",
				[
					"Wycięta strona",
					"Elyra przyznaje, że w Akademii widziała księgę z tym samym symbolem, który pojawia się w raportach o Przebudzeniu.",
					"Wiedziałam, że to zapamiętałeś."
				],
				[
					"Dawny wykładowca",
					"Jej były nauczyciel podobno opuścił stolicę tuż po królewskim zakazie handlu księgami.",
					"Jeśli go znajdziemy, chcę usłyszeć prawdę bez akademickich ozdobników."
				]
			),
			_arc(
				"elyra_debt",
				"Dług wobec wiedzy",
				[
					"Nieoddana księga",
					"Elyra zdradza, że jedna z jej ksiąg nie należała do niej i nigdy nie wróciła do właściciela.",
					"To nie jest kradzież. To... przedłużone wypożyczenie."
				],
				[
					"Cena ciszy",
					"Właściciel księgi jest związany z ludźmi handlującymi zakazaną wiedzą.",
					"Właśnie dlatego nie chciałam wciągać w to nikogo rozsądnego."
				]
			),
		],
		[
			_talk(
				"Elyra odkłada notatki. „Konkretnie. Dobrze. Jeśli mam ryzykować życie z trzema ludźmi, wolę wiedzieć, czy przynajmniej jeden z nich potrafi planować.”",
				7
			),
			_talk(
				"„Zwyczajna rozmowa?” Elyra unosi brew. „Dobrze. Zacznij od czegoś prostego: dlaczego w Varenhold wszyscy piją coś, co nazywają kawą, a smakuje jak kara?”",
				4
			),
			_talk(
				"Elyra nie przerywa ani razu. Dopiero na końcu pyta o jedną decyzję, którą sam uznałeś za mało ważną. „Właśnie ta część mnie interesowała.”",
				5
			),
		]
	),
	"kael":
	_story(
		"kael",
		"Wojownik siedzi bokiem na ławie, jakby celowo zostawiał sobie widok na wszystkie wyjścia z sali.",
		"Dobra. Ty wybierasz drogę, ja pilnuję, żeby droga nie zjadła reszty drużyny.",
		"Nie obraź się. Widziałem już zbyt wielu bohaterów, którzy byli wielcy tylko przy tablicy ogłoszeń.",
		"Jeśli kiedyś będziesz potrzebował tarczy, wiesz gdzie mnie szukać. O ile nie znajdę rozsądniejszej pracy.",
		"No proszę. Myślałem, że znalazłeś już kogoś lepszego.",
		[
			"Wiesz, co jest najgorsze w ciężkiej zbroi? Każdy uważa, że możesz nosić również jego rzeczy.",
			"Nie mam nic przeciwko Pierrotom. Dopóki nie rzucają kośćmi, żeby zdecydować, kto stoi z przodu.",
			"Najlepsza taktyka? Przeżyć pierwsze dziesięć sekund. Potem przeciwnik zwykle zaczyna popełniać błędy.",
		],
		[
			"Jeśli planujesz dziś Szczelinę, daj znać wcześniej. Tarcza też ma prawo psychicznie się przygotować.",
			"Mirela twierdzi, że moje rany 'wyglądają interesująco'. Nie wiem, czy powinienem się martwić.",
		],
		[
			"Ogień jest mały, ale przynajmniej nie próbuje nas zabić. Na razie.",
			"Śpij. Ja pierwszą wartę wezmę bez dyskusji."
		],
		[
			_arc(
				"kael_garrison",
				"Ostatni rozkaz garnizonu",
				[
					"Stary znak",
					"Kael rozpoznaje znak na jednym z raportów jako symbol oddziału, w którym kiedyś służył.",
					"Nie sądziłem, że zobaczę go jeszcze raz."
				],
				[
					"Lista poległych",
					"W archiwum brakuje kilku nazwisk ludzi z jego oddziału.",
					"Jeśli żyją, chcę wiedzieć. Jeśli nie, też chcę wiedzieć."
				]
			),
			_arc(
				"kael_oath",
				"Przysięga bez sztandaru",
				[
					"Złamana przysięga",
					"Kael odszedł z garnizonu, gdy dowódca kazał zostawić cywilów za murem.",
					"Nie żałuję. To nie znaczy, że dobrze śpię."
				],
				[
					"Świadek",
					"Ktoś z dawnego garnizonu pojawił się w Varenhold.",
					"Nie chcę pojedynku. Chcę, żeby ktoś wreszcie powiedział głośno, co się wtedy stało."
				]
			),
		],
		[
			_talk(
				"Kael kiwa głową. „Dobra odpowiedź. Nie potrzebuję dowódcy, który krzyczy najgłośniej. Potrzebuję kogoś, kto wie, kiedy powiedzieć: wracamy po swojego.”",
				7
			),
			_talk(
				"„Bez kontraktów? Wreszcie.” Kael przesuwa ci kubek. „Powiedz mi tylko, kto wymyślił ceny w tej karczmie, żebym wiedział, komu nigdy nie ufać.”",
				5
			),
			_talk(
				"Kael słucha do końca. „Przeżyłeś, więc coś zrobiłeś dobrze. Bardziej interesuje mnie, kogo wtedy nie zostawiłeś z tyłu.”",
				6
			),
		]
	),
	"nessa":
	_story(
		"nessa",
		"Łowczyni stoi przy oknie i obserwuje dziedziniec zamiast ludzi w sali. Jej łuk wygląda na zdecydowanie droższy niż płaszcz.",
		"Nie lubię dużych drużyn. Cztery osoby to jeszcze nie tłum. Spróbujmy.",
		"Za głośno o tobie mówią, a za mało widziałam. Jeszcze nie.",
		"Bez urazy. Po prostu wolę odejść, zanim zaczniemy sobie przeszkadzać.",
		"Myślałam, że już się nauczyłeś, że nie każdy dobry strzelec czeka wiecznie.",
		[
			"Najlepsza strzała to nie ta, która trafia. To ta, po której przeciwnik źle zgaduje, co poleci następne.",
			"Ktoś w Gildii nazwał mój łuk 'ładnym'. Mam nadzieję, że nie planuje go dotykać.",
			"Trzy strzały wystarczą, żeby powiedzieć bardzo dużo. Ludzie zwykle potrzebują znacznie więcej słów.",
		],
		[
			"Mam nową kombinację. Nie pytaj, czy bezpieczną. To nie jest właściwe pytanie.",
			"Na północy znowu widziano światło pod lodem. Nie wyglądało jak Aurora."
		],
		[
			"Jeżeli usłyszysz cięciwę w środku nocy, to ja. Jeżeli dwie — budź wszystkich.",
			"Nie siadaj po lewej stronie ognia. Stamtąd mam najlepszą linię strzału."
		],
		[
			_arc(
				"nessa_echo",
				"Strzała, która wróciła",
				[
					"Drugie trafienie",
					"Nessa opowiada o strzale, który po trafieniu wrócił do niej jako widmowe echo, zanim jeszcze znała tę technikę.",
					"Nie, nie pomyliłam tego z odbiciem. Strzały nie wracają przez ludzi."
				],
				[
					"Łuk bez właściciela",
					"Na wybrzeżu znaleziono podobny łuk przy ciele człowieka, którego Nessa znała.",
					"Chcę zobaczyć to miejsce. Bez świadków z Gildii."
				]
			),
			_arc(
				"nessa_rival",
				"Trzeci strzał",
				[
					"Rywalka",
					"Nessa wspomina strzelczynię, z którą przez lata wymieniała techniki i wyzwania.",
					"Nigdy nie wygrałam trzy razy z rzędu. Ona też nie."
				],
				[
					"Brak odpowiedzi",
					"Od miesięcy nie otrzymała od niej żadnego znaku.",
					"Jeśli po prostu przegrała zakład, będę wściekła. Jeśli coś się stało... bardziej."
				]
			),
		],
		[
			_talk(
				"Nessa patrzy na ciebie chwilę dłużej. „Jeśli po pierwszym nieudanym planie potrafisz zmienić drugi strzał zamiast obrażać się na świat, możemy się dogadać.”",
				6
			),
			_talk(
				"„Zwyczajnie?” Wzrusza ramionami. „Dobrze. Nie dotykaj mojego łuku i już mamy wspólny temat, w którym się zgadzamy.”",
				3
			),
			_talk(
				"Nessa zadaje tylko dwa pytania: gdzie stał przeciwnik i dlaczego nie uciekłeś. Po odpowiedzi lekko się uśmiecha. „Przynajmniej pamiętasz szczegóły.”",
				7
			),
		]
	),
	"mira":
	_story(
		"mira",
		"Pierrot obraca monetę na kostkach palców. Moneta ma dwie różne reszki i ani jednego orła.",
		"Dobra! Tylko ustalmy jedną rzecz: kiedy mówię 'mam pomysł', najpierw pytasz, czy plan obejmuje ogień.",
		"Kości mówią nie. Ja też mówię nie. Kości są bardziej uprzejme.",
		"Rozumiem. Tylko oddaj mi te trzy Goldy, które jeszcze nie zdążyłam od ciebie pożyczyć.",
		"Wiedziałam, że zatęsknisz. Rzuciłam monetą. Dwa razy.",
		[
			"Mam dwie wiadomości. Dobra: wygrałam 400 Gold. Zła: to były twoje 600 Gold.",
			"Gdyby Lewiatan połknął drugiego Lewiatana, to mielibyśmy jeden duży problem czy dwa mniejsze w środku?",
			"Elyra twierdzi, że nie da się wyrzucić siódemki na jednej kości. Brak wyobraźni jest smutny.",
		],
		[
			"Bardzo ważne: nie otwieraj mojej talii. Jedna karta gryzie.",
			"Widziałam dziś kruka, który spojrzał na mnie i odleciał w przeciwną stronę. Mądry kruk.",
			"Mam plan na Szczelinę. Plan ma trzy etapy. Znam jeden."
		],
		[
			"Jeżeli jutro obudzimy się w tym samym miejscu, uznaję noc za sukces.",
			"Ktoś chętny w kości? Stawka: pierwsza warta. I nie, nie oszukuję. Dziś."
		],
		[
			_arc(
				"mira_deck",
				"Karta bez numeru",
				[
					"Pusta karta",
					"Mira pokazuje kartę z talii, która była pusta, a dziś pojawił się na niej znak Szczeliny.",
					"Wczoraj była czysta. Przysięgam na cudze pieniądze."
				],
				[
					"Talia pamięta",
					"Karta zmienia obraz po każdej wspólnej Szczelinie.",
					"To pierwszy raz, kiedy talia śledzi mnie zamiast odwrotnie."
				]
			),
			_arc(
				"mira_name",
				"Imię na odwrocie",
				[
					"Stare imię",
					"Na odwrocie jednej z kości wyryto imię, którego Mira nie używa.",
					"Nie pytaj jeszcze. Sama nie wiem, czy chcę pamiętać."
				],
				[
					"Trupa",
					"Do Varenhold dotarła wiadomość od jej dawnej trupy.",
					"Jeśli to pułapka, będzie przynajmniej tematyczna."
				]
			),
		],
		[
			_talk(
				"Mira wyciąga kość. „Zasady drużyny? Świetnie. Ja mam jedną: jeśli mówię »uciekaj«, nie pytasz dlaczego. Jeśli mówię »mam pomysł« — wtedy pytasz koniecznie.”",
				5
			),
			_talk(
				"„O! Człowiek, który nie zaczyna rozmowy od liczby zabitych potworów.” Mira natychmiast ożywa. „Dobra, najważniejsze: słodkie czy słone śniadanie?”",
				8
			),
			_talk(
				"Mira słucha z zaskakującą uwagą. „Czyli postawiłeś wszystko na jedną decyzję i przeżyłeś? To nie jest rozsądne. Podoba mi się.”",
				7
			),
		]
	),
	"dorian":
	_story(
		"dorian",
		"Młody Poszukiwacz opowiada przy stole historię tak efektownie, że połowa słuchaczy nie zauważa, jak bardzo zmienia szczegóły.",
		"Wiedziałem, że dostrzeżesz potencjał. Nie martw się, ja też go dostrzegłem.",
		"Jeszcze chwila. Chcę dołączyć do drużyny, o której warto potem opowiadać.",
		"Trudno. Będę musiał znaleźć inną legendę, która potrzebuje narratora.",
		"Widzisz? Wiedziałem, że moja nieobecność poprawi twoją ocenę sytuacji.",
		[
			"Nie kłamię. Redaguję wspomnienia, zanim staną się historią.",
			"Jeśli przeżyjemy Szczelinę A, proszę tylko, żeby nikt nie poprawiał mnie przy opowiadaniu wersji karczemnej."
		],
		["Mam nowy tytuł dla naszej drużyny. Nie, jeszcze go nie powiem. Musi dojrzeć."],
		["Ognisko potrzebuje historii. Na szczęście jesteście ze mną."],
		[
			_arc(
				"dorian_story",
				"Historia bez bohatera",
				[
					"Stary raport",
					"Dorian odkrywa, że opowieść, na której zbudował własną legendę, należała do zapomnianego Poszukiwacza.",
					"Nie ukradłem jej. Po prostu... nikt inny jej nie pamiętał."
				],
				[
					"Prawdziwe nazwisko",
					"W raporcie znajduje się nazwisko człowieka, który nadal żyje.",
					"Muszę go znaleźć, zanim ktoś inny opowie tę historię źle."
				]
			)
		],
		[
			_talk(
				"Dorian uśmiecha się szeroko. „Współpraca, jasne. Ja robię rzeczy efektowne, ty potem w raporcie piszesz, że były przemyślane.”",
				5
			),
			_talk(
				"„Wreszcie normalny temat. Słyszałeś historię o człowieku, który próbował oszukać Orena na wadze? Nie? To usiądź.”",
				7
			),
			_talk(
				"Dorian wysłuchuje opowieści i natychmiast proponuje trzy sposoby, jak można ją opowiadać lepiej. Pod czwartym żartem widać jednak, że jest pod wrażeniem.",
				5
			)
		]
	),
	"sylvi":
	_story(
		"sylvi",
		"Kobieta suszy przy piecu mokre rękawice. Pachną ziołami, błotem i czymś, czego lepiej nie identyfikować.",
		"Może być. Jeśli umrzesz, przynajmniej nie pozwolę, żeby ciało się zmarnowało. Żartuję. Prawie.",
		"Nie teraz. Widziałam, jak ludzie wracają z wypraw, które miały być 'pewne'.",
		"Dbaj o siebie. Naprawdę. To nie był żart.",
		"No proszę. Nadal żyjesz. To znacznie ułatwia rozmowę.",
		[
			"Mokradła uczą jednej rzeczy: jeśli coś przestało śmierdzieć, prawdopodobnie jest gorzej."
		],
		["Mirela chce przepis na moją maść. Nie dostanie. Jeszcze nie."],
		["Nie dotykaj tej butelki. To nie mikstura. To obiad."],
		[
			_arc(
				"sylvi_mother",
				"Pieśń z bagna",
				[
					"Znajomy głos",
					"Sylvi słyszała w Głuchej Wodzie pieśń należącą do osoby, która zaginęła lata temu.",
					"Na bagnie martwi też potrafią mieć dobrą pamięć."
				],
				[
					"Powrót",
					"Ślad prowadzi do starego domu poza bezpiecznym traktem.",
					"Nie idę tam sama. To jedyna rozsądna rzecz, jaką dziś powiem."
				]
			)
		],
		[
			_talk(
				"Sylvi poprawia rękawice. „Moje oczekiwanie jest proste: jeśli ktoś krwawi, mówi o tym zanim zacznie widzieć dwie wersje mnie.”",
				7
			),
			_talk(
				"„Bez pracy? Dobrze.” Uśmiecha się lekko. „Jak bardzo przeszkadza ci rozmowa o pasożytach przy jedzeniu?”",
				6
			),
			_talk(
				"Sylvi zamiast pytać o bossa pyta, jak wyglądały rany po walce. „Nie patrz tak. To dużo mówi o tym, czy człowiek wie, kiedy się wycofać.”",
				5
			)
		]
	),
	"orenna":
	_story(
		"orenna",
		"Poszukiwaczka siedzi w ciszy przy ścianie. Mimo tłumu wokół niej nikt przypadkiem nie zajmuje sąsiedniego krzesła.",
		"Przyjmuję. Nie oczekuj ode mnie posłuszeństwa. Oczekuj uczciwości.",
		"Twoja siła nie jest problemem. Nie wiem jeszcze, czy masz dyscyplinę, żeby jej nie zmarnować.",
		"Rozstanie też jest decyzją. Uszanuję ją.",
		"Nie sądziłam, że wrócisz do tej decyzji. Dobrze. Ja również ją przemyślałam.",
		["Cisza nie jest niezręczna. Ludzie po prostu rzadko dają jej szansę."],
		[
			"Jeśli planujesz Szczelinę, odpocznij najpierw. Odwaga i zmęczenie brzmią podobnie tylko z daleka."
		],
		["Ogień jest dobry. Przynajmniej mówi wprost, kiedy parzy."],
		[
			_arc(
				"orenna_bell",
				"Dzwon bez klasztoru",
				[
					"Dźwięk",
					"Orenna słyszała w Szczelinie dzwon identyczny jak ten z klasztoru, który opuściła.",
					"Tamten dzwon stopiono dziesięć lat temu."
				],
				[
					"Pęknięta pieczęć",
					"W archiwach odnajduje symbol swojego zakonu przy raporcie o dawnej Szczelinie.",
					"Wygląda na to, że moi nauczyciele przemilczeli znacznie więcej niż sądziłam."
				]
			)
		],
		[
			_talk(
				"Orenna słucha w ciszy. „Nie oczekuję, że zawsze wybierzesz dobrze. Oczekuję, że będziesz umiał ponieść koszt własnego wyboru.”",
				7
			),
			_talk(
				"„Możemy milczeć przez chwilę.” Po dłuższej ciszy dodaje: „To też jest rozmowa. Zaskakująco niewielu ludzi to rozumie.”",
				5
			),
			_talk(
				"Orenna nie komentuje twojej siły. „Co zrobiłeś po zwycięstwie?” Dopiero odpowiedź na to pytanie wydaje się ją naprawdę interesować.",
				6
			)
		]
	),
	"veyn":
	_story(
		"veyn",
		"Szczupły Poszukiwacz tasuje karty, choć nie wygląda na Pierrota. Kiedy zauważa twoje spojrzenie, chowa talię bez pośpiechu.",
		"Dobrze. Zobaczymy, czy plotki o tobie są mniej przesadzone niż zwykle.",
		"Nie. Ale jeśli pytasz drugi raz, prawdopodobnie zacząłeś mnie interesować.",
		"To rozsądne. Najgorsze umowy trwają tylko dlatego, że nikt nie chce pierwszy odejść.",
		"Interesujące. Ludzie zwykle wracają po pieniądze, nie po mnie.",
		["Nie ufam ludziom, którzy mówią, że niczego nie ukrywają. To bardzo ambitne kłamstwo."],
		["Ktoś pytał dziś o ciebie na Czarnym Rynku. Nie powiedziałem nic. Jeszcze."],
		["Nie zasypiaj pierwszy. To rada, nie groźba."],
		[
			_arc(
				"veyn_market",
				"Cena nazwiska",
				[
					"Pytanie bez odpowiedzi",
					"Veyn przyznaje, że ktoś na Czarnym Rynku płaci za informacje o twojej drużynie.",
					"Nie sprzedałem. To nie znaczy, że nie chcę wiedzieć, kto kupuje."
				],
				[
					"Pośrednik",
					"Udaje się ustalić znak używany przez pośrednika.",
					"Teraz zaczyna być ciekawie. A ciekawość zwykle jest droga."
				]
			)
		],
		[
			_talk(
				"Veyn splata dłonie. „Czego oczekuję? Żebyś nie mylił zaufania z dostępem do wszystkich moich sekretów. Jeśli to akceptujesz, zaczynamy dobrze.”",
				6
			),
			_talk(
				"„Zwyczajna rozmowa bywa bardziej niebezpieczna niż przesłuchanie.” Uśmiecha się. „Ludzie wtedy zapominają pilnować odpowiedzi.”",
				5
			),
			_talk(
				"Veyn wypytuje nie o zwycięstwo, lecz o moment, w którym prawie przegrałeś. „Dobrze. Ludzie, którzy pamiętają własny strach, są mniej przewidywalni.”",
				7
			)
		]
	),
	"talia":
	_story(
		"talia",
		"Poszukiwaczka poprawia pas broni i co chwilę zerka na drzwi, jakby samo siedzenie w Gildii było stratą czasu.",
		"Wreszcie. Myślałam, że będziemy tak stać do jutra.",
		"Za wolno. Najpierw pokaż, że potrafisz podjąć decyzję zanim okazja zniknie.",
		"Szkoda. Ale wolę szybkie 'nie' od powolnego 'może'.",
		"No. Tym razem nie każ mi czekać.",
		["Jeśli plan wymaga trzech godzin dyskusji, to nie plan. To kara."],
		["Widziałam nowy alarm Szczeliny. Powiedz tylko kiedy."],
		["Kto bierze pierwszą wartę? Odpowiedź 'Talia' nie jest dozwolona."],
		[
			_arc(
				"talia_caravan",
				"Karawana popiołu",
				[
					"Pusty wóz",
					"Talia rozpoznaje opis karawany zaginionej na Popielnym Pograniczu.",
					"Jechał nią mój brat. Nie powiedziałam wcześniej, bo nie chciałam litości."
				],
				[
					"Ślady",
					"Nowy raport mówi o znalezionych śladach poza głównym traktem.",
					"Jeśli to fałszywy trop, trudno. Jeśli prawdziwy, nie wybaczę sobie zwłoki."
				]
			)
		],
		[
			_talk(
				"Talia odpowiada zanim skończysz. „Tak. Ruch, decyzja, odpowiedzialność. Jeśli coś pójdzie źle, poprawiamy w biegu, a nie robimy narady przez pół dnia.”",
				8
			),
			_talk(
				"„Pogadać? Możemy gadać idąc.” Kiedy orientuje się, że nigdzie nie idziecie, wzdycha teatralnie. „Dobra. Pięć minut.”",
				4
			),
			_talk(
				"Talia nachyla się nad stołem. „I wtedy naprawdę zostałeś? Dobra. To akurat było głupie. Ale takie głupie, które czasem chcę mieć obok siebie.”",
				7
			)
		]
	),
	"cassian":
	_story(
		"cassian",
		"Mag w nienagannie czystym płaszczu wygląda w Gildii jak człowiek, który pomylił drzwi i postanowił nikomu o tym nie mówić.",
		"Twoje wyniki są wystarczająco dobre, żebym zaryzykował reputację. Nie zmarnuj tej inwestycji.",
		"Nie. Różnica między odwagą a kompetencją jest większa, niż sugerują ballady.",
		"Było... pouczająco. To więcej, niż mówię o większości współpracowników.",
		"Wracasz z lepszą ofertą czy lepszym argumentem?",
		["W Varenhold wszystko jest albo brudne, albo podejrzane. Czasem jedno i drugie."],
		[
			"Przejrzałem twoje raporty ze Szczelin. Masz okropny charakter pisma i irytująco dobre wyniki."
		],
		["Nie chrapię. To rezonans arkaniczny."],
		[
			_arc(
				"cassian_crown",
				"Archiwum Korony",
				[
					"Pieczęć",
					"Cassian rozpoznaje królewską pieczęć na raporcie o zakazanych księgach.",
					"Mój ojciec podpisywał takie dokumenty."
				],
				[
					"Rodzinny obowiązek",
					"Rodzina Cassiana nadal pracuje dla Korony i próbuje sprowadzić go do stolicy.",
					"Nie jestem pewien, czy chcą mojego powrotu, czy mojego milczenia."
				]
			)
		],
		[
			_talk(
				"Cassian poprawia mankiet. „Oczekiwania są mało istotne. Interesują mnie standardy. Jeśli twoim standardem jest »jakoś to będzie«, oszczędźmy sobie czasu.”",
				5
			),
			_talk(
				"„Rozmowa bez celu jest luksusem.” Milknie. „...ale tutejsze wino jest tak złe, że krytykowanie go można uznać za obowiązek obywatelski.”",
				3
			),
			_talk(
				"Cassian wyłapuje każdą nieścisłość. Gdy kończysz, mówi tylko: „Nie upiększyłeś własnego błędu. To rzadsze niż talent magiczny.”",
				8
			)
		]
	),
	"lumi":
	_story(
		"lumi",
		"Dziewczyna siedzi na podłodze pod tablicą Gildii i układa sześć kości w idealnie prostą linię. Żadna nie pokazuje tej samej liczby.",
		"Dobrze. Miałam sen, w którym już się zgodziliśmy, więc to oszczędza czas.",
		"Jeszcze nie. W moim śnie miałeś inną minę.",
		"W porządku. Nie wszystkie drogi muszą kończyć się razem.",
		"Wiedziałam, że wrócisz. Nie pytaj skąd. To psuje efekt.",
		["Dzisiaj nic dziwnego się nie wydarzyło. To mnie niepokoi."],
		[
			"Jeśli zobaczysz w Szczelinie drzwi, których wcześniej nie było, nie otwieraj ich przede mną."
		],
		["Śnił mi się ten ogień. Wtedy był zielony. Wolę ten."],
		[
			_arc(
				"lumi_dream",
				"Sen, który pamięta",
				[
					"Powtarzający się sen",
					"Lumi opisuje Szczelinę, której drużyna jeszcze nie widziała.",
					"Nie wiem, czy to przyszłość. Przyszłość zwykle gorzej się ubiera."
				],
				[
					"Zgodność",
					"Kolejna Szczelina zawiera fragment dokładnie taki jak w jej opisie.",
					"Nie lubię mieć racji w takich sprawach."
				]
			)
		],
		[
			_talk(
				"Lumi patrzy gdzieś za twoje ramię. „W twojej drużynie będzie głośno. To dobrze. W cichych drużynach częściej słychać rzeczy, których nie powinno być.”",
				6
			),
			_talk(
				"„Możemy pogadać o czymś zwyczajnym.” Zastanawia się. „Czy sny o cudzych wspomnieniach liczą się jako zwyczajne?”",
				7
			),
			_talk(
				"Lumi zna zakończenie twojej historii sekundę przed tobą i marszczy brwi. „Dobrze. Tym razem wydarzyło się tak samo.”",
				6
			)
		]
	),
	"brann":
	_story(
		"brann",
		"Mężczyzna z marynarskim płaszczem śmieje się z czegoś przy barze, ale za każdym razem, gdy ktoś wspomina Czarną Flotę, przestaje na pół sekundy.",
		"Pewnie! Najwyżej wszyscy zginiemy, a wtedy nikt nie będzie mógł narzekać na decyzję.",
		"Jeszcze nie, przyjacielu. Muszę wiedzieć, czy jesteś typem człowieka, który wraca po swoich.",
		"Bez urazy. Morze nauczyło mnie, że czasem lepiej zejść z pokładu przed sztormem.",
		"Ha! Wiedziałem, że brakowało ci kogoś, kto mówi za dużo.",
		["Nie boję się duchów. Boję się marynarzy, którzy twierdzą, że nie boją się duchów."],
		["Jeśli znów pójdziemy na Wrak, proszę: bez dzwonów."],
		["Ktoś ma rum? Nie? Świetnie, to pozostaje nam odwaga. Znacznie gorszy trunek."],
		[
			_arc(
				"brann_fleet",
				"Czwarty dzwon",
				[
					"Noc na morzu",
					"Brann był na statku, który usłyszał cztery dzwony Czarnej Floty, choć według legend powinny być trzy.",
					"Czwarty zadzwonił pod nami."
				],
				[
					"Lista załogi",
					"Na Wraku znajduje się nazwisko człowieka z jego dawnej załogi.",
					"Nie chcę go znaleźć żywego. Boję się, że znajdę go inaczej."
				]
			)
		],
		[
			_talk(
				"Brann uderza dłonią w stół. „Jedna zasada: wracamy po swoich. Druga: jeśli pierwsza zawiedzie, nie udajemy potem, że to była strategia.”",
				8
			),
			_talk(
				"„Bez roboty? Świetnie! Mogę ci opowiedzieć, dlaczego nigdy nie grasz w karty z kapitanem, który ma tylko jedną rękę, ale pięć asów.”",
				7
			),
			_talk(
				"Brann żartuje przez pierwszą połowę opowieści. Przy najgorszym momencie przestaje. „Tak. Znam ten rodzaj ciszy po walce.”",
				6
			)
		]
	),
}

static var _pair_banter := {
	"elyra|mira":
	[
		[
			"Elyra: To matematycznie niemożliwe.",
			"Mira: A jednak wyrzuciłam sześć.\nElyra: Dwoma kośćmi k4."
		],
		[
			"Mira: Chcesz nauczyć się oszukiwać kości?",
			"Elyra: Chcę nauczyć kości przestrzegania praw natury."
		],
	],
	"kael|mira":
	[
		[
			"Kael: Nie rzucaj kością, żeby wybrać wartę.",
			"Mira: Spokojnie. Tym razem rzucam, kto NIE bierze warty."
		]
	],
	"dorian|nessa":
	[
		[
			"Dorian: W mojej wersji opowieści ten strzał przeleciał przez trzy cele.",
			"Nessa: W mojej wersji zamykasz usta po pierwszym."
		]
	],
	"cassian|mira":
	[
		[
			"Cassian: Przypadek nie jest metodą.",
			"Mira: To dziwne, bo metoda właśnie uratowała ci życie."
		]
	],
	"brann|elyra":
	[
		[
			"Brann: Magowie zawsze tak patrzą, jakby wiedzieli coś, czego nie wiem?",
			"Elyra: Nie zawsze. Czasem wiemy kilka rzeczy."
		]
	],
	"orenna|talia": [["Talia: Możemy już iść?", "Orenna: Możemy. Pytanie, czy możemy też wrócić."]],
}


static func get_story(template_id: String) -> StoryDefinitionClass:
	return _stories.get(template_id)


static func get_pair_banter(first_template_id: String, second_template_id: String) -> Array:
	return _pair_banter.get(_pair_key(first_template_id, second_template_id), [])


static func all_arc_ids(template_id: String) -> Array[String]:
	var result: Array[String] = []
	var story := get_story(template_id)
	if story == null:
		return result
	for arc: PersonalArcClass in story.arcs:
		result.append(arc.arc_id)
	return result


static func _story(
	template_id: String,
	intro: String,
	recruit_success: String,
	recruit_fail: String,
	farewell: String,
	return_line: String,
	idle_lines: Array[String],
	messages: Array[String],
	camp_lines: Array[String],
	arcs: Array[PersonalArcClass],
	conversations: Array[Dictionary]
) -> StoryDefinitionClass:
	return StoryDefinitionClass.new(
		template_id,
		intro,
		recruit_success,
		recruit_fail,
		farewell,
		return_line,
		idle_lines,
		messages,
		camp_lines,
		arcs,
		conversations
	)


static func _arc(arc_id: String, title: String, first: Array, second: Array) -> PersonalArcClass:
	return (
		PersonalArcClass
		. new(
			arc_id,
			title,
			[
				(
					QuestStageClass
					. new(
						str(first[0]),
						str(first[1]),
						0,
						[
							DialogueChoiceClass.new(
								"Powiedz mi więcej.", str(first[2]), 3, "%s:heard" % arc_id
							),
							DialogueChoiceClass.new(
								"Nie musisz mówić, jeśli nie chcesz.",
								"Doceniam to. Może innym razem.",
								2,
								"%s:space" % arc_id
							),
						]
					)
				),
				(
					QuestStageClass
					. new(
						str(second[0]),
						str(second[1]),
						1,
						[
							DialogueChoiceClass.new(
								"Zrobimy to razem.", str(second[2]), 4, "%s:together" % arc_id
							),
							DialogueChoiceClass.new(
								"Najpierw upewnijmy się, że to ma sens.",
								"Rozsądnie. Właśnie dlatego pytam ciebie.",
								2,
								"%s:careful" % arc_id
							),
						]
					)
				),
				(
					QuestStageClass
					. new(
						"Domknięcie",
						"Po kolejnej wspólnej wyprawie temat wraca. Tym razem nie brzmi już jak prośba o pomoc, tylko jak decyzja, którą kompan chce podjąć razem z tobą.",
						2,
						[
							DialogueChoiceClass.new(
								"Jestem z tobą do końca.",
								"Dobrze. W takim razie kończymy to po naszemu.",
								5,
								"%s:finished" % arc_id
							),
							DialogueChoiceClass.new(
								"Zrób to, co uważasz za właściwe.",
								"Może właśnie tego potrzebowałem: żeby ktoś nie wybierał za mnie.",
								4,
								"%s:finished" % arc_id
							),
						]
					)
				),
			]
		)
	)


static func _talk(response: String, impression: int) -> Dictionary:
	return {"response": response, "impression": impression}


static func _pair_key(first_template_id: String, second_template_id: String) -> String:
	var ids := [first_template_id, second_template_id]
	ids.sort()
	return "%s|%s" % ids
