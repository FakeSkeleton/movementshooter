extends RigidBody3D

@export var force = 100

func _process(_delta):
	if Input.is_action_just_pressed("attack"):
		$Area3D.monitoring = !$Area3D.monitoring

func _on_area_3d_body_entered(body):
	if body.is_in_group("Player"):
		var pos1 = position
		var pos2 = body.position
		
		body.gravityVec = Vector3.DOWN * 0
		body.velocity = Vector3(body.position - position).normalized() * force
		body.gravityVec += Vector3(body.position - position).normalized() * force * 0.1
		
		print("BOOM")
		print(body.velocity)
		
