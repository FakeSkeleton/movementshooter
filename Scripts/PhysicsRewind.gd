extends RigidBody3D

@onready var collision = $CollisionShape3D

@export var rewindDuration = 5
var rewinding: bool = false
var rewindValues = {
	"position": [],
	"velocity": [],
	"rotation": [],
	}

func _physics_process(_delta):
	if Input.is_action_just_pressed("attack"):
		print("object: " + str(len(rewindValues["position"])))
	
	if not rewinding:
		if rewindDuration * Engine.physics_ticks_per_second == rewindValues["position"].size():
			for key in rewindValues.keys():
				rewindValues[key].pop_front()
				
		rewindValues["position"].append(position)
		rewindValues["velocity"].append(linear_velocity)
		rewindValues["rotation"].append(rotation_degrees)
	else:
		compute_rewind()
		
		
func compute_rewind():
	var pos = rewindValues["position"].pop_back()
	var vel = rewindValues["velocity"].pop_back()
	var rot1 = rewindValues["rotation"].pop_back()
	
	if rewindValues["position"].is_empty():
		rewinding = false
		collision.set_deferred("disabled", false)
		position = pos
		linear_velocity = vel
		rotation_degrees = rot1
		return
		
	position = pos
	linear_velocity = vel
	rotation_degrees = rot1
		
func rewind():
	collision.set_deferred("disabled", !collision.disabled)
	rewinding = !rewinding
