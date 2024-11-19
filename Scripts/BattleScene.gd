extends Node2D

signal battle_ended

enum BattleState {
	PLAYER_TURN,
	ENEMY_TURN
}

var battle_state = BattleState.PLAYER_TURN
var enemy_health
var enemy_defense
var enemy_damage
var player_defense = 100
var damage
var player_defending = false


@onready var enemy_info = get_node("EnemyInfo")
@onready var playeranim = $Player

@onready var battle_start = $Transition
@onready var attack_button = $CombatUI/VBoxContainer/Attack
@onready var defend_button = $CombatUI/VBoxContainer/Defend
@onready var skill_button = $CombatUI/VBoxContainer/Skill
@onready var run_button = $CombatUI/VBoxContainer/Run
@onready var camera = $Camera2D  # Battle scene camera
@onready var player_health_label = $CombatUI/PlayerHealthLabel  # Add a Label node for player health
@onready var enemy_health_label = $CombatUI/EnemyHealthLabel  # Add a Label node for enemy health
@onready var hit_flash_animation_enemy = $Enemy/HitFlashAnimationEnemy
@onready var hit_flash_animation_player = $Player/HitFlashAnimationPlayer

func _ready():
	battle_start.play("Battle_Start")
	enemy_health = enemy_info.health()
	enemy_defense = enemy_info.defense()
	enemy_damage = enemy_info.damage()
	
	camera.make_current()
	playeranim.play("Idle")
	
	# Connect button signals
	if not attack_button.is_connected("pressed", Callable(self, "_on_attack_pressed")):
		attack_button.connect("pressed", Callable(self, "_on_attack_pressed"))
	if not defend_button.is_connected("pressed", Callable(self, "_on_defend_pressed")):
		defend_button.connect("pressed", Callable(self, "_on_defend_pressed"))
	if not skill_button.is_connected("pressed", Callable(self, "_on_skill_pressed")):
		skill_button.connect("pressed", Callable(self, "_on_skill_pressed"))
	if not run_button.is_connected("pressed", Callable(self, "_on_run_pressed")):
		run_button.connect("pressed", Callable(self, "_on_run_pressed"))

	update_ui()

func update_ui():
	# Display player and enemy health
	player_health_label.text = "Player Health: " + str(GameData.player_health)
	enemy_health_label.text = "Enemy Health: " + str(enemy_health)

func _on_attack_pressed():
	if battle_state == BattleState.PLAYER_TURN:
		attack()
		end_turn()

func _on_defend_pressed():
	if battle_state == BattleState.PLAYER_TURN:
		defend()
		end_turn()

func _on_skill_pressed():
	if battle_state == BattleState.PLAYER_TURN:
		skill()
		end_turn()

func _on_run_pressed():
	if battle_state == BattleState.PLAYER_TURN:
		run_away()

func attack():
	var player_damage = 50
	damage = 100 * player_damage / (100 + enemy_defense)
	enemy_health -= damage
	hit_flash_animation_enemy.play("hit_flash")
	print("You attacked the enemy for", damage, "damage!")
	update_ui()

func defend():
	player_defending = true
	print("You defend! Damage taken next turn will be reduced.")

func skill():
	var skill_damage = 80
	damage = 100 * skill_damage / (100 + enemy_defense)
	enemy_health -= damage
	hit_flash_animation_enemy.play("hit_flash")
	print("You used a skill for", skill_damage, "damage!")
	update_ui()

func run_away():
	print("You ran away!")
	emit_signal("battle_ended")

func enemy_turn():
	if player_defending:
		enemy_damage = enemy_damage / 2

	damage = 100 * enemy_damage / (100 + player_defense)
	GameData.player_health -= damage
	hit_flash_animation_player.play("hit_flash_player")
	print("Enemy attacks you for", enemy_damage, "damage!")
	update_ui()
	player_defending = false
	battle_state = BattleState.PLAYER_TURN
	player_buttons()

func end_turn():
	if enemy_health <= 0:
		await get_tree().create_timer(.4).timeout
		battle_start.play("Enemy_Dead")
		print("Enemy defeated!")
		
		await get_tree().create_timer(1.0).timeout
		emit_signal("battle_ended")
		
	elif GameData.player_health <= 0:
		print("You have been defeated.")
		emit_signal("battle_ended")
		
	else:
		battle_state = BattleState.ENEMY_TURN
		player_buttons()
		await get_tree().create_timer(1.0).timeout
		enemy_turn()

func player_buttons():
	if battle_state == BattleState.PLAYER_TURN:
		attack_button.disabled = false
		skill_button.disabled = false
		defend_button.disabled = false
		run_button.disabled = false
		
	elif battle_state == BattleState.ENEMY_TURN:
		attack_button.disabled = true
		skill_button.disabled = true
		defend_button.disabled = true
		run_button.disabled = true


func end_battle():
	emit_signal("battle_ended")
	print("Battle ended!")
	get_tree().change_scene("res://Scenes/Main.tscn")
