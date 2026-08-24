class_name OpenWorldEncounterState
extends RefCounted

const ELITE_MODIFIER_IDS := ["furious", "armored", "vampiric", "cursed", "elemental"]
const REGION_BOSS_IDS := ["azhar", "leviathan_north"]

var elite_discoveries: Array[String] = []
var elite_miss_streaks := {}
var region_boss_respawns := {}
