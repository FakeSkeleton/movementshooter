extends CharacterBody3D

var mouseSensitivity = 1

@export var speed = 10
var currentSpeed = speed

const dashSpeed = 100

#Some export variables :3
@export var acceleration = 10
@export var jumpHeight = 13
@export var jumpTokens = 2
@export var gravity = 9.8

var wallCollision
var aim

#For some booleans
@onready var isSliding: bool = false
@onready var quickFalling: bool = false
@onready var wallRunning: bool = false

@onready var fpsCounter = $"Pause/FPS Counter"
@onready var collision = $CollisionShape3D

#Just some vector stuff
var gravityVec = Vector3()
var direction = Vector3()

#Rewind stuff
@export var rewindDuration = 5
var rewinding: bool = false
var rewindValues = {
	"position": [],
	"velocity": [],
	"rotation1": [],
	"rotation2": [],
	"rotation3": [],
	"scale": [],
	"tokens": [],
}

func _input(event):
	#Camera things, essentially just allowing the mouse to actually MOVE the camera
	if event is InputEventMouseMotion and !rewinding:
		rotation_degrees.y -= event.relative.x * mouseSensitivity / 18
		$Head.rotation_degrees.x -= event.relative.y * mouseSensitivity / 18
		$Head.rotation_degrees.x = clamp($Head.rotation_degrees.x, -90, 90)
		
func jump(height, delta):
	#Call this function to jump, removing a jump token then resetting gravity and obviously jumping
	if jumpTokens >= 1:
		gravityVec = Vector3.DOWN * gravity * 2 * delta
		gravityVec += Vector3.UP * height
		jumpTokens -= 1
		
func sliding(delta):
	#A bit scuffed ngl but it works for what it is, plus its kinda cool.
	#First I increase the speed by a bit based off of how fast you currently are
	if !isSliding:
		currentSpeed = currentSpeed * 1.5
	
	#Then I do some variable things as you see here, all very basic stuff
	isSliding = true
	direction.z += -1
	scale.y = 0.5
	$Head/Camera.rotation.z = deg_to_rad(-10)
	
	#Finally the longer you slide the slower you go until you are essentially not moving anymore
	while isSliding:
		currentSpeed -= currentSpeed / 20 * delta
		await get_tree().create_timer(0.1).timeout
		
func _ready():
	Engine.physics_ticks_per_second = 120
	Engine.time_scale = 1
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	#Just applying some info to some variables
	direction = Vector3()
	aim = $Head/Camera.get_global_transform().basis;
	
	#Main movement part
	if Input.is_action_pressed("forward") and !isSliding:
		direction.z += -1
	if Input.is_action_pressed("backward") and !isSliding:
		direction.z += 1
	if Input.is_action_pressed("left") and !isSliding:
		direction.x += -1
	if Input.is_action_pressed("right") and !isSliding:
		direction.x += 1
		
	#Quick falling just giga gravity for a bit 
	if !is_on_floor() and !is_on_wall() and Input.is_action_just_pressed("fall"):
		gravityVec.y = -gravity * 5
			
	#Kinda in the name, but its for wallrunning :)
	if is_on_wall_only():
		if !wallRunning:
			#Reset gravity then go up a bit based off of current speed to reward speed
			gravityVec = Vector3.DOWN * gravity * 2 * delta
			gravityVec += Vector3.UP * currentSpeed / 3
			
		#Setting gravity lower and resetting jump tokens while also getting the collision normal
		if !get_last_slide_collision().get_collider().is_class("RigidBody3D"):
			wallRunning = true
			wallCollision = get_slide_collision(0).get_normal()
			jumpTokens = 2
			gravity = 4.9
		
		#All of this to check whether the wall is on my left or right then tilting the camera accordingly
			if $LeftWall.is_colliding():
				$Head/Camera.rotation.z = deg_to_rad(-15)
			elif $RightWall.is_colliding():
				$Head/Camera.rotation.z = deg_to_rad(15)
			else:
				$Head/Camera.rotation.z = deg_to_rad(0)
			
		#This allows me to stick to the wall
			velocity += -wallCollision * speed
		
		#So I can stop sticking to the wall
			if Input.is_action_just_pressed("jump"):
				velocity = wallCollision * speed * 5
			
	else:
	#Just to reset everything if none of the above conditions are met
		wallRunning = false
		$Head/Camera.rotation.z = deg_to_rad(0)
		gravity = 9.8
		
	#Purely debug purposes
	if Input.is_action_just_pressed("attack"):
		print("player: " + str(len(rewindValues["position"])))
		
	#Normalizing my direction so as not to get double speed on diagonals
	direction = direction.normalized()
	
	#Just setting my speed higher, but whats interesting is if I dont have that "elif" statement, even if it is
	#pass, the sliding after sprint feels weird. No clue why
	if Input.is_action_pressed("sprint") and !isSliding:
		currentSpeed = speed * 2
	elif isSliding:
		pass
	else:
		currentSpeed = speed
		
	#What activates the slide
	if Input.is_action_pressed("slide") and !is_on_wall_only():
		sliding(delta)
	else:
		isSliding = false
		scale.y = 1
		
	#This is the gravity code, just making me fall a bit more every frame
	if not is_on_floor() and !rewinding:
		gravityVec += Vector3.DOWN * gravity * 2 * delta
	else:
	#Resets jump tokens and gravity vector
		gravityVec = Vector3.DOWN * gravity / 10
		jumpTokens = 2
		
	#When the jump button is pressed jump. However, if sliding and jump button pressed, jump higher
	if Input.is_action_just_pressed("jump") and !isSliding:
		jump(jumpHeight, delta)
	elif Input.is_action_just_pressed("jump") and isSliding and is_on_floor():
		jump(jumpHeight * 2, delta)
		
	#Dash time. Lose one jump token when using a dash
	if Input.is_action_just_pressed("grapple") and jumpTokens >= 1:
		jumpTokens -= 1
		#Then check where the player is aiming and set the dash direction towards that point
		var dashDirection = Vector3()
		dashDirection += aim.z * -1
		dashDirection = dashDirection.normalized();
		#Finally dash there by applying the dash direction to the velocity vector
		var dashVector = dashDirection * dashSpeed;
		velocity += dashVector;
		
	#Sets the time scale of the game to be 20% if a button is held
	if Input.is_action_pressed("slowdown"):
		Engine.time_scale = 0.2
	else:
		Engine.time_scale = 1
		
	#This is gonna be hard bc I dont even fully understand but basically this first part is checking
	#whether or not the specified array has too many values, and if so remove the oldest set of values
	#ps. I dont need to check for every key as they all gain values at the same time
	if not rewinding:
		if rewindDuration * Engine.physics_ticks_per_second == rewindValues["position"].size():
			for key in rewindValues.keys():
				rewindValues[key].pop_front()
				
		#I apply each key a specific value each frame, so say on frame 10 my position is 3, 9, 10, 
		#value 10 would be 3, 9, 10 and so on
		rewindValues["position"].append(position)
		rewindValues["velocity"].append(velocity)
		rewindValues["rotation1"].append(rotation_degrees)
		rewindValues["rotation2"].append($Head/Camera.rotation_degrees)
		rewindValues["rotation3"].append($Head.rotation_degrees)
		rewindValues["scale"].append(scale)
		rewindValues["tokens"].append(jumpTokens)
	else:
		#If rewinding IS true however we begin the rewind
		compute_rewind()
		
		
	#Making the direction relative to where the mouse is facing
	direction = direction.rotated(Vector3.UP, rotation.y)
	#Setting the y velocity to be my gravity vector as stated above 
	velocity.y = gravityVec.y
	#Actually allowing me to move, with acceleration being how fast it is for me to reach that velocity
	#and stop from the velocity
	velocity = velocity.lerp(direction * currentSpeed, acceleration * delta)
	#Neccesary for literally all the movement code to function
	move_and_slide()
	
	for index in get_slide_collision_count():
		var collided = get_slide_collision(index)
		if collided.get_collider().is_class("RigidBody3D"):
			collided.get_collider().apply_impulse(-collided.get_normal() * currentSpeed, collided.get_position() - position)
	
func _process(_delta):
	#FPS counter, simple as 
	fpsCounter.text = "Fps: " + str(Engine.get_frames_per_second())
		
func compute_rewind():
	#Each variable corresponds to a key in the rewind values variable, which then takes the most recent
	#value, sets their own value to such and deletes it
	var pos = rewindValues["position"].pop_back()
	var vel = rewindValues["velocity"].pop_back()
	var rot1 = rewindValues["rotation1"].pop_back()
	var rot2 = rewindValues["rotation2"].pop_back()
	var rot3 = rewindValues["rotation3"].pop_back()
	var sca = rewindValues["scale"].pop_back()
	var tok = rewindValues["tokens"].pop_back()
	
	#Resetting everything to normal if the keys are empty so as not to completely break the engine
	if rewindValues["position"].is_empty():
		rewinding = false
		collision.set_deferred("disabled", false)
		position = pos
		velocity = vel
		rotation_degrees = rot1
		$Head/Camera.rotation_degrees = rot2
		$Head.rotation_degrees = rot3
		scale = sca
		jumpTokens = tok
		return
		
	#Every frame is now forcing the player's position, rotation, scale and jump tokens to be set to
	#the most recent value in each corresponding key
	position = pos
	velocity = vel
	rotation_degrees = rot1
	$Head/Camera.rotation_degrees = rot2
	$Head.rotation_degrees = rot3
	scale = sca
	jumpTokens = tok
		
func rewind():
	#To remove collision just in case some things happen. Makes it easier in any case
	collision.set_deferred("disabled", !collision.disabled)
	rewinding = !rewinding
