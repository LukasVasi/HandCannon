extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005

# Camera bob variables
const BOB_FREQUENCY = 2.0
const BOB_AMPLITUDE = 0.08
var bob_t = 0.0

# Fov variables
const BASE_FOV = 75.0 # TODO: turn this into a setting
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes (9.8).
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Rotate around one axis each for head and camera to avoid Euler related wackyness
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		# Prevent head cartwheels
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))
		# TODO: Turn the player according to the camera
		# rotation.y = head.rotation.y

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Handle sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	# This piece of code uses transform.basis to determine where the player is looking
	# to obtain the movement direction relative to where the player's facing
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction: # if the direction is non-zero as in the player has pressed a button
			# move with SPEED towards that direction
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else: # if the player isn't pressing anything
			velocity.x = lerp(velocity.x, 0.0, delta * 6.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 6.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 4.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 4.0)

	# Head bob
	bob_t += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(bob_t)
	
	# FOV
	var velocity_length_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2.0)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_length_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLITUDE
	return pos
