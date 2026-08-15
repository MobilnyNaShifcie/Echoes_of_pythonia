class_name GuildRumor
extends RefCounted

var text: String
var minimum_rank: String
var requires_market: bool
var required_milestone: String


func _init(
	rumor_text: String,
	rank := "F",
	market_required := false,
	milestone_required := "",
) -> void:
	text = rumor_text
	minimum_rank = rank
	requires_market = market_required
	required_milestone = milestone_required
