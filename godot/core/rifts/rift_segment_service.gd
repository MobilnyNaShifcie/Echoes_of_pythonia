class_name RiftSegmentService
extends RefCounted

const EnemyClass := preload("res://core/combat/enemy.gd")
const RiftCatalogClass := preload("res://core/rifts/rift_catalog.gd")
const RiftInstanceClass := preload("res://core/rifts/rift_instance.gd")

const EVENT_THRESHOLD := 0.16
const ELITE_THRESHOLD := 0.34
const CAMP_SEGMENT_INDICES := [4, 9, 14, 19]
const PARTY_SCALE := 2.5
const EVENTS := [
	[
		"Ślad poprzedniej drużyny",
		"Na ziemi leży zerwany znak Gildii i świeża krew. Nie ma ciał ani śladów odwrotu.",
	],
	[
		"Niemożliwy korytarz",
		"Droga prowadzi przez miejsce, które z zewnątrz nie mogłoby pomieścić własnego wnętrza.",
	],
	[
		"Echo rozmowy",
		"Przez chwilę słyszycie własne głosy wypowiadające zdania, których nikt jeszcze nie powiedział.",
	],
	[
		"Pęknięta skrzynia",
		"Znajdujecie porzucone zapasy. Część jest prawdziwa, część rozpada się w pył po dotknięciu.",
	],
	[
		"Cisza",
		"Przez kilka minut Szczelina przestaje wydawać jakiekolwiek dźwięki. Nawet wasze kroki milkną.",
	],
]


static func segment_kind(rift: RiftInstanceClass, segment_index: int) -> String:
	if rift == null or segment_index < 0:
		return ""
	if segment_index >= rift.segment_count - 1:
		return "boss"
	if segment_index in CAMP_SEGMENT_INDICES and segment_index < rift.segment_count - 1:
		return "camp"
	if segment_index == int(rift.segment_count / 2.0):
		return "miniboss"
	var roll := named_rng(rift, "segment", segment_index).randf()
	if roll < EVENT_THRESHOLD:
		return "event"
	if roll < ELITE_THRESHOLD:
		return "elite"
	return "battle"


static func event_text(rift: RiftInstanceClass, segment_index: int) -> Dictionary:
	if rift == null or segment_index < 0:
		return {}
	var rng := named_rng(rift, "event", segment_index)
	var event: Array = EVENTS[rng.randi_range(0, EVENTS.size() - 1)]
	return {"title": str(event[0]), "text": str(event[1])}


static func create_enemy(
	rift: RiftInstanceClass, player_level: int, segment_index: int, kind: String
) -> EnemyClass:
	if rift == null or kind not in ["battle", "elite", "miniboss", "boss"]:
		return null
	var theme: Dictionary = RiftCatalogClass.get_theme(rift.theme_id)
	if theme == null:
		return null
	var rng := named_rng(rift, "enemy:%s" % kind, segment_index)
	var rank_scale := float(RiftCatalogClass.RANK_SCALES[rift.rank_code])
	var depth := 1.0 + segment_index / float(maxi(1, rift.segment_count - 1)) * 0.35
	var elite := kind in ["elite", "miniboss"]
	var boss := kind == "boss"
	var name := rift.boss_name
	var factor := 3.2
	if not boss:
		var names: Array = theme.elite_names if elite else theme.enemy_names
		name = str(names[rng.randi_range(0, names.size() - 1)])
		factor = 2.0 if kind == "miniboss" else 1.45 if elite else 1.0
	var hp := int((55 + player_level * 18) * rank_scale * depth * PARTY_SCALE * factor)
	var attack := int(
		(
			(5 + player_level * 1.65)
			* rank_scale
			* depth
			* (1.10 if elite else 1.0)
			* (1.18 if boss else 1.0)
		)
	)
	var defense := int(
		(
			1
			+ player_level / 4.0
			+ RiftCatalogClass.rank_index(rift.rank_code) * 1.2
			+ (2 if elite else 0)
			+ (2 if boss else 0)
		)
	)
	for modifier_id: String in rift.modifier_ids:
		var modifier = RiftCatalogClass.get_modifier(modifier_id)
		hp = int(hp * modifier.enemy_hp_multiplier)
		attack = int(attack * modifier.enemy_attack_multiplier)
		defense += modifier.enemy_defense_bonus
	return (
		EnemyClass
		. new(
			{
				"enemy_id": "%s-%d-%s" % [rift.rift_id, segment_index, kind],
				"display_name": name,
				"max_hp": maxi(1, hp),
				"attack": maxi(1, attack),
				"defense": maxi(0, defense),
				"rank": "boss" if boss else "elite" if elite else "normal",
			}
		)
	)


static func mana_cost_multiplier(rift: RiftInstanceClass) -> float:
	if rift == null:
		return 1.0
	var multiplier := 1.0
	for modifier_id: String in rift.modifier_ids:
		multiplier *= RiftCatalogClass.get_modifier(modifier_id).player_mana_cost_multiplier
	return multiplier


static func combat_rng(rift: RiftInstanceClass, segment_index: int) -> RandomNumberGenerator:
	return named_rng(rift, "combat", segment_index)


static func named_rng(
	rift: RiftInstanceClass, substream: String, segment_index: int
) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if rift == null:
		return rng
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(
		("rift-segment-v1|%d|%s|%d" % [rift.seed, substream, segment_index]).to_utf8_buffer()
	)
	var digest := context.finish()
	var seed_value := 0
	for index in 7:
		seed_value = (seed_value << 8) | int(digest[index])
	rng.seed = seed_value
	return rng
