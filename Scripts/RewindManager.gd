extends Node

@onready var player = get_parent().get_node("Player")

func _process(_delta):
	if (Input.is_action_just_pressed("rewind") and !player.rewindValues["position"].is_empty()
		and (len(player.rewindValues["position"]) >= 120 or player.rewinding == true)):
			get_tree().call_group("Rewindable", "rewind")
