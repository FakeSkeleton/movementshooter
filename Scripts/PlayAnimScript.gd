extends Node

@onready var children = get_children()

func _ready():
	for child in children:
		child.get_node("AnimationPlayer").play("move")
