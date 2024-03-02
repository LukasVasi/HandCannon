extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005

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

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	# This piece of code uses transform.basis to determine where the player is looking
	# to obtain the movement direction relative to where the player's facing
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction: # if the direction is non-zero as in the player has pressed a button
		# move with SPEED towards that direction
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else: # if the player isn't pressing anything
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
