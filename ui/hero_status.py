from player.player import Player
from player.talents import available_tree_points, specialization_name
from systems.guild_progression import GuildProgress, current_guild_rank
from systems.carry_weight import carry_status
from ui.console import print_header


def show_hero_status(player: Player, guild_progress: GuildProgress | None = None) -> None:
    print_header()
    print()
    print(f"BOHATER: {player.display_name}")
    print("-" * 58)
    print(f"Poziom: {player.level}")
    specialization = specialization_name(player)
    class_text = player.character_class.display_name
    if specialization:
        class_text += f" — {specialization}"
    print(f"Klasa: {class_text}")
    if guild_progress is not None:
        rank=current_guild_rank(guild_progress)
        print(f"Ranga Gildii: {rank.display_name}")
        print(f"Reputacja Gildii: {guild_progress.reputation}")
    print(f"EXP: {player.experience}/{player.experience_to_next_level()}")
    print(f"Do następnego poziomu: {player.experience_remaining_to_next_level()} EXP")
    print(f"Gold: {player.gold}")
    print(f"Rubiny: {player.rubies}")
    load = carry_status(player)
    print(f"Udźwig plecaka: {load.current_kg:.1f}/{load.capacity_kg:.1f} kg ({load.display_name})")
    print()
    print("STATYSTYKI GŁÓWNE")
    print("-" * 58)
    print(f"HP:    {player.stats.current_hp}/{player.stats.max_hp}")
    print(f"ATK:   {player.stats.attack}")
    print(f"DEF:   {player.stats.defense}")
    print(f"UNIK:  {player.stats.dodge:.1f}%")
    print(f"MANA:  {player.stats.current_mana}/{player.stats.max_mana}")
    if player.stats.magic_power > 0:
        print(f"MOC MAG.: {player.stats.magic_power}")
    print()
    print("MODYFIKATORY EKWIPUNKU")
    print("-" * 58)
    print(f"Krytyk:              +{player.stats.crit_chance:.1f}%")
    print(f"Obrażenia krytyczne: +{player.stats.crit_damage:.1f}%")
    print(f"Obrażenia umiejęt.:  +{player.stats.skill_damage:.1f}%")
    print(f"Penetracja pancerza: +{player.stats.armor_penetration:.1f}%")
    print(f"Obrażenia vs elity:  +{player.stats.damage_vs_elite:.1f}%")
    print(f"Obrażenia vs bossy:  +{player.stats.damage_vs_boss:.1f}%")
    print(f"Regeneracja HP:      +{player.stats.health_regen}/turę")
    print()
    print("ODPORNOŚCI ELEMENTALNE")
    print("-" * 58)
    for name, value in player.stats.resistances.as_dict().items():
        print(f"{name:<12} {value}%")
    print()
    print("ATRYBUTY")
    print("-" * 58)
    for name, value in player.attributes.as_dict().items():
        if name == "Szczęście" and player.character_class.code != "pierrot":
            continue
        print(f"{name:<16} {value}")
    if player.character_class.code == "pierrot":
        print("  Szczęście wpływa na Kości Losu, Żetony Losu i niewielką premię do rzadkich łupów.")
    print()
    print(f"Wolne punkty atrybutów: {player.unspent_attribute_points}")
    print(f"Wolne punkty pasywne: {player.available_passive_points}")
    if player.character_class.code != "none":
        print(f"Wolne punkty drzewka: {available_tree_points(player)}")
