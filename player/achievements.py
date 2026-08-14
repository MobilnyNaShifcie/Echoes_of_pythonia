from dataclasses import dataclass, field


@dataclass(frozen=True)
class AchievementDefinition:
    achievement_id: str
    name: str
    description: str
    title: str


ACHIEVEMENTS: tuple[AchievementDefinition, ...] = (
    AchievementDefinition(
        "first_blood",
        "Pierwsza krew",
        "Pokonaj pierwszego przeciwnika.",
        "Łowca",
    ),
    AchievementDefinition(
        "nature_breaker",
        "Pogromca Natury",
        "Pokonaj Strażnika Natury.",
        "Pogromca Natury",
    ),
    AchievementDefinition(
        "executioners_end",
        "Koniec Egzekutora",
        "Pokonaj Leśnego Egzekutora.",
        "Kat Egzekutora",
    ),
    AchievementDefinition(
        "silence_the_mother",
        "Cisza nad Głuchą Wodą",
        "Pokonaj Matkę Głuchej Wody.",
        "Ten, Który Uciszył Matkę",
    ),
    AchievementDefinition(
        "aurora_hunter",
        "Pod Zorzą",
        "Odnieś zwycięstwo podczas Zorzy Polarnej.",
        "Dziecko Zorzy",
    ),
    AchievementDefinition(
        "master_smith",
        "Mistrz Kowadła",
        "Ulepsz dowolny przedmiot do +10.",
        "Mistrz Kowadła",
    ),
    AchievementDefinition(
        "guild_veteran",
        "Weteran Gildii",
        "Osiągnij rangę S — Legenda w Gildii Poszukiwaczy.",
        "Weteran Gildii",
    ),
)

_ACHIEVEMENT_BY_ID = {
    achievement.achievement_id: achievement
    for achievement in ACHIEVEMENTS
}

DEFAULT_TITLE = "Wędrowiec"


@dataclass
class AchievementBook:
    unlocked: set[str] = field(default_factory=set)
    equipped_title: str = DEFAULT_TITLE

    def unlock(self, achievement_id: str) -> AchievementDefinition | None:
        if achievement_id not in _ACHIEVEMENT_BY_ID:
            raise KeyError(f"Nieznane osiągnięcie: {achievement_id}")
        if achievement_id in self.unlocked:
            return None
        self.unlocked.add(achievement_id)
        return _ACHIEVEMENT_BY_ID[achievement_id]

    def available_titles(self) -> list[str]:
        titles = [DEFAULT_TITLE]
        for achievement in ACHIEVEMENTS:
            if achievement.achievement_id in self.unlocked:
                titles.append(achievement.title)
        return titles

    def equip_title(self, title: str) -> None:
        if title not in self.available_titles():
            raise ValueError("Ten tytuł nie został jeszcze odblokowany.")
        self.equipped_title = title


def achievement_exists(achievement_id: str) -> bool:
    return achievement_id in _ACHIEVEMENT_BY_ID


def get_achievement(achievement_id: str) -> AchievementDefinition:
    return _ACHIEVEMENT_BY_ID[achievement_id]
