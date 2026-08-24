class_name ContractObjective
extends RefCounted

const KILL_ENEMY := "kill_enemy"
const KILL_REGION := "kill_region"
const COLLECT := "collect"
const KILL_ELITE := "kill_elite"
const KILL_ELITE_REGION := "kill_elite_region"
const KILL_MINIBOSS := "kill_miniboss"
const COMPLETE_DUNGEON := "complete_dungeon"
const TYPES := [
	KILL_ENEMY,
	KILL_REGION,
	COLLECT,
	KILL_ELITE,
	KILL_ELITE_REGION,
	KILL_MINIBOSS,
	COMPLETE_DUNGEON,
]

var objective_type: String
var target_id: String
var required_count: int
var consume_items: bool


func _init(type: String, target := "", required := 1, consume := false) -> void:
	objective_type = type
	target_id = target
	required_count = required
	consume_items = consume
