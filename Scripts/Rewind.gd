extends StaticBody3D

@onready var collision = $CollisionShape3D

@export var rewindDuration = 5
var rewinding: bool = false
var rewindValues = {
	"position": []
	}

func _ready():
	pass

func _physics_process(_delta):
	if not rewinding:
		if rewindDuration * Engine.physics_ticks_per_second == rewindValues["position"].size():
			for key in rewindValues.keys():
				rewindValues[key].pop_front()
				
		rewindValues["position"].append(position)
	else:
		compute_rewind()
		
		
func compute_rewind():
	var pos = rewindValues["position"].pop_back()
	if rewindValues["position"].is_empty():
		rewinding = false
		collision.set_deferred("disabled", false)
		$AnimationPlayer.speed_scale = -$AnimationPlayer.speed_scale
		position = pos
		return
		
	position = pos
	
func rewind():
	collision.set_deferred("disabled", !collision.disabled)
	$AnimationPlayer.speed_scale = -$AnimationPlayer.speed_scale
	rewinding = !rewinding
