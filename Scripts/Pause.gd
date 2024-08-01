extends CanvasLayer

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = !get_tree().paused
		$Control.visible = get_tree().paused
		
		if get_tree().paused == false:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_quit_pressed():
	get_tree().quit()


func _on_continue_pressed():
	get_tree().paused = !get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Control.visible = get_tree().paused
