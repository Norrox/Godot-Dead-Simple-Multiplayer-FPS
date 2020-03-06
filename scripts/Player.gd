extends KinematicBody

var speed = 6.5
var movement = Vector3()
var jump_force = 5
var mouse_sensitivity = 1

var health = 100

func _ready():
	# If the name of this instanced node is the same as the client id we can control it
	var is_me = name == str( get_tree().get_network_unique_id() )
	set_physics_process(is_me) # Keyboard inputs allowed
	set_process_input(is_me) # Mouse vision allowed

	# Setup nodes:
	$Camera.current = is_me
	$Crosshair.visible = is_me
	$Camera/Weapon.visible = !is_me
	$HUD.visible = is_me

	# Data to send remotely:
	rset_config("transform", MultiplayerAPI.RPC_MODE_REMOTE)
	$Camera.rset_config("rotation", MultiplayerAPI.RPC_MODE_REMOTE)
	$Camera/FlashLight.rset_config("visible", MultiplayerAPI.RPC_MODE_REMOTE)

func send_data(): # Data sent each frame (not optimized, but easier to read and manage)
	rset_unreliable("transform", transform)
	$Camera.rset_unreliable("rotation", $Camera.rotation)
	$Camera/FlashLight.rset("visible", $Camera/FlashLight.visible)

func _physics_process(delta):
	
	$HUD/Health.text = str(health) + " HP"
	
	var direction_2D = Vector2() # Controls in 2D to normalize the directions
	direction_2D.y = Input.get_action_strength("backward") - Input.get_action_strength("forward")
	direction_2D.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction_2D = direction_2D.normalized()
	
	# 2D direction normalized added to 3D vector
	movement.z = direction_2D.y * speed
	movement.x = direction_2D.x * speed
	movement.y -= 9.8 * delta
	
	movement = movement.rotated(Vector3.UP, rotation.y)
	
	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"):
			movement.y = jump_force
	
	movement = move_and_slide(movement, Vector3.UP)
	
	other_abilities()
	send_data()

func _input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation_degrees.y -= event.relative.x * mouse_sensitivity / 10
			$Camera.rotation_degrees.x -= event.relative.y * mouse_sensitivity / 10
			$Camera.rotation_degrees.x = clamp($Camera.rotation_degrees.x, -90, 90)

func other_abilities():
	if Input.is_action_just_pressed("shoot"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		shoot()
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("Flashlight"):
		$Camera/FlashLight.visible = !$Camera/FlashLight.visible

func shoot():
	if $Camera/RayCast.get_collider() != null and $Camera/RayCast.get_collider().get("health") != null:
		$Camera/RayCast.get_collider().health -= 10
		$HUD/Debug.text = "Enemy: " + str($Camera/RayCast.get_collider().health) + " HP"

func _on_DisconnectButton_pressed():
	NETWORK.leave_game()
