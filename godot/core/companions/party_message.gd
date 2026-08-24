class_name PartyMessage
extends RefCounted

var day := 0
var sender_id := ""
var sender_name := ""
var text := ""
var read := false


func _init(
	initial_day := 0,
	initial_sender_id := "",
	initial_sender_name := "",
	initial_text := "",
	initial_read := false
) -> void:
	day = initial_day
	sender_id = initial_sender_id
	sender_name = initial_sender_name
	text = initial_text
	read = initial_read
