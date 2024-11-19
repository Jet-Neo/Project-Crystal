extends CharacterBody2D

enum MovementState {
	IDLE,
	WALKING,
	RUNNING
}

var speed = 100
var run_speed = 200
var current_state = MovementState.IDLE
var run_button = "ui_shift"
var direction = Vector2.ZERO
var encounter_chance = 0.01
var is_in_encounter = false
var is_in_wild_zone = false

@onready var Anim = $AnimatedSprite2D
@onready var camera = $Camera2D
@export var battle_scene: PackedScene
var current_battle_instance: Node = null  # To keep track of the battle instance

func _ready():
	
	Anim.play("MC_Idle")
	camera.make_current()
	
	if GameData.player_position != Vector2.ZERO:
		global_position = GameData.player_position

	# Attempt connection with WildZone using absolute path
	connect_wild_zone_signals()

func _process(delta):
	if is_in_encounter:
		return

	direction = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1

	direction = direction.normalized()
	var is_running = Input.is_action_pressed(run_button)

	if direction != Vector2.ZERO:
		if is_running:
			change_state(MovementState.RUNNING)
		else:
			change_state(MovementState.WALKING)
		
		if is_in_wild_zone and randf() < encounter_chance:
			trigger_encounter()
	else:
		change_state(MovementState.IDLE)

	match current_state:
		MovementState.IDLE:
			velocity = Vector2.ZERO
		MovementState.WALKING:
			velocity = direction * speed
		MovementState.RUNNING:
			velocity = direction * run_speed

	move_and_slide()

func change_state(new_state: MovementState):
	if current_state != new_state:
		current_state = new_state

func trigger_encounter():
	is_in_encounter = true
	GameData.player_position = global_position
	
	# Instantiate the battle scene and hide the main scene
	current_battle_instance = battle_scene.instantiate()
	get_tree().root.add_child(current_battle_instance)
	get_tree().current_scene.visible = false  # Hide the main scene
	current_battle_instance.connect("battle_ended", Callable(self, "end_battle"))  # Listen for the end of battle signal

func end_battle():
	# Cleanup the battle scene instance
	camera.make_current()
	if current_battle_instance:
		current_battle_instance.queue_free()  # Queue the battle scene for deletion
		current_battle_instance = null

	# Restore the main scene visibility
	get_tree().current_scene.visible = true
	is_in_encounter = false

	# Reconnect WildZone signals upon return
	connect_wild_zone_signals()

func connect_wild_zone_signals():
	# Attempt to find WildZone using absolute path
	print("Attempting to locate WildZone node at path /root/Main/WildZone")
	var wild_zone = get_node_or_null("/root/Main/WildZone")
	
	if wild_zone:
		print("WildZone found and signals connected.")
		
		# Disconnect any existing connections to avoid duplicates
		if wild_zone.is_connected("body_entered", Callable(self, "_on_WildZone_body_entered")):
			wild_zone.disconnect("body_entered", Callable(self, "_on_WildZone_body_entered"))
		if wild_zone.is_connected("body_exited", Callable(self, "_on_WildZone_body_exited")):
			wild_zone.disconnect("body_exited", Callable(self, "_on_WildZone_body_exited"))
		
		# Connect the signals
		wild_zone.connect("body_entered", Callable(self, "_on_WildZone_body_entered"))
		wild_zone.connect("body_exited", Callable(self, "_on_WildZone_body_exited"))
	else:
		print("WildZone not found - please check the path and node structure.")

func _on_WildZone_body_entered(body):
	if body == self:
		is_in_wild_zone = true
		print("Entered wild zone - encounters enabled")

func _on_WildZone_body_exited(body):
	if body == self:
		is_in_wild_zone = false
		print("Exited wild zone - encounters disabled")
