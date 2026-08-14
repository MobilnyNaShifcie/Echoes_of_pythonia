# Wybrane bronie-białe kruki z bossów dungeonowych.
# Średnie Obrażenia są oddzielną właściwością instancji i nie zajmują
# miejsca w losowych affixach T1-T5.
SIGNATURE_DUNGEON_WEAPONS: dict[str, dict[str, object]] = {
    "grandmaster_sword": {
        "source_boss_id": "order_grandmaster",
        "average_damage_min": -5,
        "average_damage_max": 15,
    },
    "varek_sabre": {
        "source_boss_id": "admiral_varek",
        "average_damage_min": -8,
        "average_damage_max": 22,
    },
}
