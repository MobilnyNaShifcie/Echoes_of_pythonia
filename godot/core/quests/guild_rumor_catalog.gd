class_name GuildRumorCatalog
extends RefCounted

# Long lore strings preserve the terminal game's complete, authored rumor text.
# gdlint: disable=max-line-length

const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const GuildRumorClass := preload("res://core/quests/guild_rumor.gd")


static func get_all() -> Array[GuildRumorClass]:
	return [
		(
			GuildRumorClass
			. new(
				"Na Zmierzchowych Równinach znowu znaleziono stracha na wróble, który stał kilka kroków dalej niż poprzedniego dnia. Nikt nie chce sprawdzać, czy jutro podejdzie jeszcze bliżej."
			)
		),
		(
			GuildRumorClass
			. new(
				"Garran twierdzi, że dobra stal śpiewa pod młotem. Wczoraj jedna podobno odpowiedziała mu szeptem. Od tamtej pory kuźnia zamyka się wcześniej."
			)
		),
		(
			GuildRumorClass
			. new(
				"Ktoś przyniósł do Gildii mapę z zaznaczoną drogą przez Czarny Bór. Problem w tym, że ścieżka na pergaminie zmienia położenie każdej nocy."
			)
		),
		(
			GuildRumorClass
			. new(
				"Mirela kupuje składniki, o które rozsądny człowiek nie pyta. Jeśli mikstura zaczyna mrugać, podobno dolicza podwójną cenę."
			)
		),
		(
			GuildRumorClass
			. new(
				"Marynarze z północy mówią, że przy bezwietrznej nocy spod lodu słychać dzwony okrętowe. Nikt rozsądny nie wypływa wtedy z portu.",
				"E"
			)
		),
		(
			GuildRumorClass
			. new(
				"Na Popielnym Pograniczu zaginęła karawana. Konie, wozy i skrzynie znaleziono nietknięte. Brakowało tylko ludzi i wszystkich naczyń z wodą.",
				"E"
			)
		),
		(
			GuildRumorClass
			. new(
				"Królestwo objęło stare księgi bojowe zakazem handlu. Oficjalnie chodzi o bezpieczeństwo. Nieoficjalnie nikt na sali nie wierzy, że Korona boi się papieru.",
				"D"
			)
		),
		(
			GuildRumorClass
			. new(
				"Strażnicy spalili przed zachodnią bramą cały wóz zakazanych ksiąg. Dziwne tylko, że woźnica wrócił wieczorem z cięższą sakiewką niż rano.",
				"D"
			)
		),
		(
			GuildRumorClass
			. new(
				"Mówią, że jedna przeczytana strona Księgi Ścieżki potrafi zmienić sposób walki człowieka bardziej niż dziesięć lat treningu. Nic dziwnego, że Korona chce mieć je pod kluczem.",
				"C"
			)
		),
		(
			GuildRumorClass
			. new(
				"Czarny Rynek? Bajki dla naiwnych. Tak przynajmniej powiedział najemnik, który chwilę później kupił mapę pod stołem.",
				"C"
			)
		),
		(
			GuildRumorClass
			. new(
				"Jeśli ktoś w karczmie zapyta, czy szukasz wiedzy, której nie ma w bibliotekach, najpierw sprawdź, czy nie ma królewskiego sygnetu pod rękawem.",
				"C"
			)
		),
		(
			GuildRumorClass
			. new(
				"Podobno istnieją handlarze, którzy za jedną Księgę Ścieżki żądają więcej złota niż kosztuje mały dom. Najgorsze, że podobno znajdują kupców.",
				"C",
				true
			)
		),
		(
			GuildRumorClass
			. new(
				"Na Czarnym Rynku nie negocjuje się dwa razy. Pierwsza cena jest obrazą, druga próbą, a trzeciej podobno już nie słyszysz.",
				"C",
				true
			)
		),
		(
			GuildRumorClass
			. new(
				"Nie wszystkie statki Czarnej Floty zatonęły. Niektóre po prostu przestały potrzebować żywej załogi.",
				"C",
				false,
				"dungeon:black_fleet_wreck"
			)
		),
		(
			GuildRumorClass
			. new(
				"Ktoś przysięga, że Admirał Varek wydał ostatni rozkaz długo po własnej śmierci. Gildia oficjalnie nie komentuje takich opowieści.",
				"B",
				false,
				"dungeon:black_fleet_wreck"
			)
		),
		(
			GuildRumorClass
			. new(
				"W archiwach Gildii istnieją kontrakty, których Nowicjusz nigdy nie zobaczy. Nie dlatego, że są trudne. Dlatego, że niektórych zleceniodawców oficjalnie nie ma.",
				"B"
			)
		),
		(
			GuildRumorClass
			. new(
				"Królestwo płaci za konfiskowane księgi, ale jeszcze więcej płaci za nazwiska tych, którzy potrafią je czytać. Ciekawe, czego bardziej się boją.",
				"B"
			)
		),
		(
			GuildRumorClass
			. new(
				"Podobno żył Wojownik tak ciężko opancerzony, że przeciwnicy przestali próbować go zranić. Wtedy nauczył się ich prowokować.",
				"B"
			)
		),
		(
			GuildRumorClass
			. new(
				"Wędrowny błazen miał pokonać trzech bandytów lancą i parą kości. Świadkowie nie są zgodni, czy miał niewiarygodne szczęście, czy po prostu oszukiwał rzeczywistość.",
				"B"
			)
		),
		(
			GuildRumorClass
			. new(
				"Łowcy z dalekiego wschodu opowiadają o strzelcach, których strzały zostawiają po sobie widmowe echa. Trzeci strzał podobno nigdy nie jest tylko trzecim strzałem.",
				"B"
			)
		),
		(
			GuildRumorClass
			. new(
				"W starej wieży znaleziono ślady po dwóch zaklęciach rzuconych w tej samej chwili przez jednego maga. Akademia nazwała raport niemożliwym i natychmiast go utajniła.",
				"A"
			)
		),
		(
			GuildRumorClass
			. new(
				"Najstarsi Mistrzowie mówią, że Księgi Mistrzostwa są tylko wstępem. Prawdziwie zakazana wiedza nie wzmacnia techniki — ona zmienia zasady, według których technika działa.",
				"A"
			)
		),
		(
			GuildRumorClass
			. new(
				"Na północ od znanych map podobno stoją ruiny miasta, którego nazwy nie ma w żadnym królewskim rejestrze. Gildia płaci za każdą wiarygodną wzmiankę.",
				"S"
			)
		),
		(
			GuildRumorClass
			. new(
				"Legenda Gildii nie pyta, czy plotka jest prawdziwa. Pyta, ile osób zginęło, próbując ją sprawdzić.",
				"S"
			)
		),
		(
			GuildRumorClass
			. new(
				"Na Równinach podobno widziano całe stado wilków uciekające przed czymś, czego nikt później nie znalazł. Zwykle to ludzie uciekają przed wilkami."
			)
		),
		(
			GuildRumorClass
			. new(
				"Skrybowie z archiwum zamówili ostatnio więcej zamków niż pergaminu. Ktoś najwyraźniej bardziej boi się czytających niż złodziei.",
				"E"
			)
		),
		(
			GuildRumorClass
			. new(
				"W Czarnym Borze wycinano kiedyś znak w korze drzew, żeby coś trzymać z dala od traktu. Dzisiaj te same znaki pojawiają się po wewnętrznej stronie pni.",
				"D"
			)
		),
		(
			GuildRumorClass
			. new(
				"Podobno królewski dekret nie zakazuje czytania Ksiąg. Zakazuje ich sprzedaży, przewozu, kopiowania, wypożyczania i „przypadkowego znalezienia”. Bardzo wygodne.",
				"D"
			)
		),
		(
			GuildRumorClass
			. new(
				"Jeden z archiwistów Gildii mówi, że stare pieczęcie nie wyglądały jak symbole kultów. Bardziej jak zamki. Tylko nikt nie wie, co miały zamykać.",
				"C"
			)
		),
		(
			GuildRumorClass
			. new(
				"Na Pustkowiach popiół podobno układa się w ten sam wzór, który widziano na kamieniach Głuchej Wody. Przypadek robi się coraz mniej przekonujący.",
				"C"
			)
		),
		(
			GuildRumorClass
			. new(
				"Korona wysłała do Gildii trzech urzędników po raporty o przebudzeniach. Wrócili z pustymi rękami. Gildia twierdzi, że dokumenty gdzieś się zapodziały.",
				"B"
			)
		),
		(
			GuildRumorClass
			. new(
				"Niektórzy Mistrzowie sądzą, że Aurora nie wzmacnia potworów. Ona tylko pozwala im przypomnieć sobie, czym były wcześniej.",
				"A"
			)
		),
	]


static func available(
	reputation: int,
	milestones: Array[String],
	market_unlocked := false,
) -> Array[GuildRumorClass]:
	var rumors: Array[GuildRumorClass] = []
	for rumor in get_all():
		if not GuildProgressionServiceClass.has_rank(reputation, rumor.minimum_rank):
			continue
		if rumor.requires_market and not market_unlocked:
			continue
		if not rumor.required_milestone.is_empty() and rumor.required_milestone not in milestones:
			continue
		rumors.append(rumor)
	return rumors


static func pick_available(
	reputation: int,
	milestones: Array[String],
	rng: RandomNumberGenerator,
	market_unlocked := false,
) -> GuildRumorClass:
	var rumors := available(reputation, milestones, market_unlocked)
	if rumors.is_empty():
		return null
	return rumors[rng.randi_range(0, rumors.size() - 1)]
