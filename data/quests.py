QUEST_ORDER = ('black_venom',
 'cult_beneath_roots',
 'bones_of_silentwater',
 'herbs_for_mirela',
 'knights_without_graves',
 'mother_below',
 'seal_of_drowned')


QUEST_DATA: dict[str, dict[str, object]] = {'black_venom': {'title': 'Czarny jad',
                 'description': 'Mirela potrzebuje świeżych gruczołów jadowych z Czarnego Boru. Gildia płaci '
                                'za materiał, zanim alchemiczka sama pójdzie go szukać.',
                 'recommended_level': 2,
                 'objective_type': 'collect',
                 'target_id': 'venom_gland',
                 'required_count': 2,
                 'reward_exp': 90,
                 'reward_gold': 140},
 'cult_beneath_roots': {'title': 'Kult pod korzeniami',
                        'description': 'Patrole widziały ludzi w czarnych szatach przy starym trakcie. '
                                       'Gildia chce, by kilku z nich przestało wracać do Varenhold.',
                        'recommended_level': 3,
                        'objective_type': 'kill',
                        'target_id': 'forest_cultist',
                        'required_count': 3,
                        'reward_exp': 130,
                        'reward_gold': 180},
 'bones_of_silentwater': {'title': 'Kości Głuchej Wody',
                          'description': 'Z mokradeł wychodzą topielcy i podchodzą coraz bliżej do traktu. '
                                         'Zlecenie jest proste tylko na papierze: położyć czterech z '
                                         'powrotem.',
                          'recommended_level': 5,
                          'objective_type': 'kill',
                          'target_id': 'drowned_dead',
                          'required_count': 4,
                          'reward_exp': 210,
                          'reward_gold': 280},
 'herbs_for_mirela': {'title': 'Ziele z czarnej wody',
                      'description': 'Bagienne Wiedźmy zbierają roślinę, która rośnie tylko w stojącej, '
                                     'martwej wodzie. Mirela zapłaci Gildii za trzy świeże pędy.',
                      'recommended_level': 5,
                      'objective_type': 'collect',
                      'target_id': 'witch_herb',
                      'required_count': 3,
                      'reward_exp': 180,
                      'reward_gold': 240,
                      'reward_item_id': 'strong_healing_potion',
                      'reward_item_quantity': 2},
 'knights_without_graves': {'title': 'Rycerze bez grobów',
                            'description': 'Dwóch rycerzy Zatopionego Zakonu blokuje drogę przez kamienny '
                                           'nasyp. Ich herby są starsze niż samo Varenhold. Gildia chce '
                                           'oczyścić przejście.',
                            'recommended_level': 6,
                            'objective_type': 'kill',
                            'target_id': 'sunken_knight',
                            'required_count': 2,
                            'reward_exp': 300,
                            'reward_gold': 400},
 'mother_below': {'title': 'Matka z głębin',
                  'description': 'Nocą cała Głucha Woda odpowiada na jeden głos. Jeśli opowieści są '
                                 'prawdziwe, pod mokradłem istnieje istota, którą topielcy nazywają Matką.',
                  'recommended_level': 7,
                  'objective_type': 'kill',
                  'target_id': 'drowned_mother',
                  'required_count': 1,
                  'reward_exp': 550,
                  'reward_gold': 800,
                  'reward_item_id': 'strong_healing_potion',
                  'reward_item_quantity': 3},
 'seal_of_drowned': {'title': 'Pieczęć Zatopionych',
                     'description': 'Gildia zdobyła informację, że rycerze Zatopionego Zakonu strzegą śladów '
                                    'prowadzących do jego dawnej krypty. Pokonaj trzech i odzyskaj klucz, '
                                    'zanim zniknie pod mokradłem.',
                     'recommended_level': 7,
                     'objective_type': 'kill',
                     'target_id': 'sunken_knight',
                     'required_count': 3,
                     'reward_exp': 220,
                     'reward_gold': 250,
                     'reward_item_id': 'ancient_order_key',
                     'reward_item_quantity': 1}}


# v0.23.2 — Akt I: Ślady Przebudzenia
# Dziewięć jednorazowych zadań tworzy spójną linię od pierwszych wypraw
# aż po wydarzenia związane z Czarną Flotą. Wysokopoziomowe etapy używają
# istniejących trofeów jako dowodów i celowo ich nie zużywają.
_STORY_ACT_I_ORDER = (
    "awakening_missing_recruits",
    "awakening_black_wax",
    "awakening_voice_beneath_roots",
    "awakening_beneath_still_water",
    "awakening_nameless_seal",
    "awakening_breathing_crypt",
    "awakening_ash_remembers",
    "awakening_bells_beneath_ice",
    "awakening_last_order",
)

QUEST_ORDER = QUEST_ORDER + _STORY_ACT_I_ORDER

QUEST_DATA.update({
    "awakening_missing_recruits": {
        "title": "Ci, którzy nie wrócili",
        "description": (
            "Trójka Nowicjuszy miała wrócić ze Zmierzchowych Równin przed zmrokiem. "
            "Znaleziono tylko ich wygaszone ognisko i ślady wilków biegnących... w przeciwną stronę. "
            "Gildia prosi cię o sprawdzenie okolicy i przepędzenie drapieżników z traktu."
        ),
        "recommended_level": 0,
        "unlock_level": 0,
        "objective_type": "kill",
        "target_id": "wolf",
        "required_count": 2,
        "reward_exp": 45,
        "reward_gold": 70,
        "guild_reputation": 40,
        "story_arc": "Akt I — Ślady Przebudzenia",
        "chapter": "Rozdział I — Droga, która ucichła",
        "completion_text": (
            "Jeden z zaginionych Nowicjuszy wraca do Gildii sam. Twierdzi, że wilki nie polowały na ich grupę — "
            "uciekały przed czymś poruszającym się po równinach po zmroku. Nie potrafi opisać czego."
        ),
    },
    "awakening_black_wax": {
        "title": "Czarny wosk",
        "description": (
            "Przy rzeczach zaginionych znaleziono odłamek czarnego wosku z niepełną pieczęcią. "
            "Podobnych znaków używają kultyści Czarnego Boru. Gildia chce wiedzieć, czy to przypadek."
        ),
        "recommended_level": 2,
        "unlock_level": 2,
        "prerequisite_quest_id": "awakening_missing_recruits",
        "objective_type": "kill",
        "target_id": "forest_cultist",
        "required_count": 2,
        "reward_exp": 100,
        "reward_gold": 150,
        "guild_reputation": 50,
        "story_arc": "Akt I — Ślady Przebudzenia",
        "chapter": "Rozdział I — Droga, która ucichła",
        "completion_text": (
            "Na szatach kultystów znajdujesz identyczny znak. Starszy skryba Gildii rozpoznaje tylko fragment: "
            "symbol jest starszy od obecnego królestwa, ale ktoś niedawno zaczął używać go ponownie."
        ),
    },
    "awakening_voice_beneath_roots": {
        "title": "Głos spod korzeni",
        "description": (
            "Kultyści powtarzali słowa o „głosie pod korzeniami”. Gildia wysyła cię głębiej do Czarnego Boru. "
            "Masz odnaleźć źródło niepokojących znaków i wrócić z dowodem, że las naprawdę się zmienia."
        ),
        "recommended_level": 4,
        "unlock_level": 4,
        "prerequisite_quest_id": "awakening_black_wax",
        "objective_type": "collect",
        "target_id": "blackwood_heart",
        "required_count": 1,
        "reward_exp": 180,
        "reward_gold": 260,
        "guild_reputation": 70,
        "story_arc": "Akt I — Ślady Przebudzenia",
        "chapter": "Rozdział II — Głos spod korzeni",
        "completion_text": (
            "Serce Czarnego Boru pulsuje jeszcze długo po przyniesieniu do Varenhold. Mirela odkrywa na nim ten sam "
            "wzór co na czarnym wosku. Po raz pierwszy Gildia zapisuje w raporcie jedno słowo: Przebudzenie."
        ),
    },
    "awakening_beneath_still_water": {
        "title": "To, czego nie powinno być pod wodą",
        "description": (
            "Na Głuchej Wodzie pojawiają się mgły układające się w ten sam znak, który znaleziono w Borze. "
            "Wędrowcy Mgieł wychodzą z nich częściej niż zwykle. Gildia chce, byś sprawdził, co próbują osłaniać."
        ),
        "recommended_level": 6,
        "unlock_level": 6,
        "prerequisite_quest_id": "awakening_voice_beneath_roots",
        "objective_type": "kill",
        "target_id": "mist_walker",
        "required_count": 3,
        "reward_exp": 250,
        "reward_gold": 340,
        "guild_reputation": 50,
        "story_arc": "Akt I — Ślady Przebudzenia",
        "chapter": "Rozdział III — Czarna woda",
        "completion_text": (
            "Po rozproszeniu mgieł odnajdujesz kamienny słup wbity głęboko w mokradło. Wyryty na nim znak nie jest "
            "wezwaniem. Wygląda raczej jak część dawnej pieczęci mającej coś zatrzymać pod ziemią."
        ),
    },
    "awakening_nameless_seal": {
        "title": "Pieczęć bez imienia",
        "description": (
            "Skrybowie podejrzewają, że fragmenty symbolu prowadzą do Zatopionego Zakonu. "
            "Potrzebują próbki energii z najgłębszej części Głuchej Wody, zanim Korona przejmie ich raporty."
        ),
        "recommended_level": 8,
        "unlock_level": 8,
        "prerequisite_quest_id": "awakening_beneath_still_water",
        "objective_type": "collect",
        "target_id": "silentwater_heart",
        "required_count": 1,
        "reward_exp": 360,
        "reward_gold": 500,
        "guild_reputation": 70,
        "story_arc": "Akt I — Ślady Przebudzenia",
        "chapter": "Rozdział III — Czarna woda",
        "completion_text": (
            "Serce Głuchej Wody reaguje na stary znak jak klucz na zamek. W archiwach znajduje się wzmianka, że "
            "Zatopiony Zakon nie czcił tego, co było pod kryptą. Próbował to uśpić."
        ),
    },
    "awakening_breathing_crypt": {
        "title": "Krypta, która oddycha",
        "description": (
            "Gildia chce obejrzeć Fragment Zatopionej Korony — dowód, że dotarłeś do serca Krypty Zakonu. "
            "Nie oddawaj trofeum na własność; skrybowie potrzebują go tylko do porównania znaków."
        ),
        "recommended_level": 10,
        "unlock_level": 10,
        "prerequisite_quest_id": "awakening_nameless_seal",
        "objective_type": "collect",
        "target_id": "crown_fragment",
        "required_count": 1,
        "reward_exp": 480,
        "reward_gold": 700,
        "guild_reputation": 90,
        "consume_objective_items": False,
        "story_arc": "Akt I — Ślady Przebudzenia",
        "chapter": "Rozdział IV — Zatopiona pamięć",
        "completion_text": (
            "Fragment Korony nosi tę samą pieczęć, ale od wewnętrznej strony. To potwierdza najgorszą teorię: "
            "dawny Zakon był strażnikiem, a nie źródłem zagrożenia. Coś osłabia zabezpieczenia pozostawione przez niego."
        ),
    },
    "awakening_ash_remembers": {
        "title": "Popiół pamięta",
        "description": (
            "Wieści z Popielnego Pogranicza mówią o podobnym znaku wśród ruin Azhara. Jeśli posiadasz jego Pieczęć, "
            "Gildia chce ją zbadać. Przedmiot pozostanie twoją własnością."
        ),
        "recommended_level": 12,
        "unlock_level": 12,
        "prerequisite_quest_id": "awakening_breathing_crypt",
        "objective_type": "collect",
        "target_id": "azhar_sigil",
        "required_count": 1,
        "reward_exp": 650,
        "reward_gold": 900,
        "guild_reputation": 90,
        "consume_objective_items": False,
        "story_arc": "Akt I — Ślady Przebudzenia",
        "chapter": "Rozdział V — Popiół pamięta",
        "completion_text": (
            "Pieczęć Azhara nie jest identyczna, ale jej rdzeń tworzy część tego samego wzoru. Ktoś lub coś budzi "
            "miejsca oddalone od siebie o setki mil. Skrybowie zaczynają nanosić je na jedną mapę."
        ),
    },
    "awakening_bells_beneath_ice": {
        "title": "Dzwony pod lodem",
        "description": (
            "Północ odpowiada na wydarzenia z Pustkowi. Łuska Lewiatana może rozstrzygnąć, czy kolejne przebudzenie "
            "jest częścią tego samego zjawiska. Gildia potrzebuje tylko możliwości jej zbadania."
        ),
        "recommended_level": 15,
        "unlock_level": 15,
        "prerequisite_quest_id": "awakening_ash_remembers",
        "objective_type": "collect",
        "target_id": "leviathan_scale",
        "required_count": 1,
        "reward_exp": 850,
        "reward_gold": 1200,
        "guild_reputation": 110,
        "consume_objective_items": False,
        "story_arc": "Akt I — Ślady Przebudzenia",
        "chapter": "Rozdział VI — Dzwony pod lodem",
        "completion_text": (
            "Na łusce Lewiatana pojawia się wzór dopiero po ogrzaniu jej nad płomieniem. To kolejny fragment pieczęci. "
            "W tym samym czasie do Varenhold dociera raport o dzwonach słyszanych z wraków Czarnej Floty."
        ),
    },
    "awakening_last_order": {
        "title": "Ostatni rozkaz",
        "description": (
            "Fragment Szabli Admirała Vareka zachował ślad energii z Wraku Czarnej Floty. Gildia chce porównać go "
            "z pozostałymi dowodami. Fragment nie zostanie zużyty ani skonfiskowany."
        ),
        "recommended_level": 18,
        "unlock_level": 18,
        "prerequisite_quest_id": "awakening_bells_beneath_ice",
        "objective_type": "collect",
        "target_id": "varek_sabre_fragment",
        "required_count": 1,
        "reward_exp": 1100,
        "reward_gold": 1600,
        "guild_reputation": 130,
        "consume_objective_items": False,
        "story_arc": "Akt I — Ślady Przebudzenia",
        "chapter": "Finał Aktu I — Ostatni rozkaz",
        "completion_text": (
            "Gdy wszystkie znaki zostają nałożone na siebie, tworzą niemal pełną pieczęć obejmującą znane regiony. "
            "Brakuje jednego fragmentu — leżącego poza granicami obecnych map. Gildia zamyka raport pod kluczem. "
            "Akt I — Ślady Przebudzenia zostaje zakończony, ale pytanie pozostaje: co właściwie próbuje się obudzić?"
        ),
    },
})
