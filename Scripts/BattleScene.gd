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
var defense_damage

@onready var enemy_info = get_node("EnemyInfo")
@onready var playeranim = $Player

@onready var battle_start = $Transition
@onready var attack_button = $CombatUI/VBoxContainer/Attack
@onready var defend_button = $CombatUI/VBoxContainer/Defend
@onready var skill_button = $CombatUI/VBoxContainer/Skill
@onready var run_button = $CombatUI/VBoxContainer/Run
@onready var camera = $Camera2D
@onready var player_health_label = $CombatUI/PlayerHealthLabel
@onready var enemy_health_label = $CombatUI/EnemyHealthLabel
@onready var hit_flash_animation_enemy = $Enemy/HitFlashAnimationEnemy
@onready var hit_flash_animation_player = $Player/HitFlashAnimationPlayer

# Skill menu variables
@onready var skill_menu = $SkillMenu
@onready var skill_list = $SkillMenu/SkillList
@onready var back_button = $SkillMenu/BackButton

# Textbox for battle events
@onready var battle_log = $CombatUI/BattleLog

# Player skills (loaded from GameData)
var current_skills = []

# Status effects
var player_status_effects = []  # Missing in your code
var enemy_status_effects = []   # Missing in your code

func _ready():
	battle_start.play("Battle_Start")
	enemy_health = enemy_info.health()
	enemy_defense = enemy_info.defense()
	enemy_damage = enemy_info.damage()
	defense_damage = enemy_damage / 2
	
	camera.make_current()
	playeranim.play("Idle")
	
	# Load skills from GameData
	current_skills = GameData.player_skills
	
	# Connect buttons
	attack_button.connect("pressed", Callable(self, "_on_attack_pressed"))
	defend_button.connect("pressed", Callable(self, "_on_defend_pressed"))
	skill_button.connect("pressed", Callable(self, "_on_skill_pressed"))
	run_button.connect("pressed", Callable(self, "_on_run_pressed"))
	back_button.connect("pressed", Callable(self, "_on_back_pressed"))
	
	# Set focus neighbors for keyboard navigation
	attack_button.focus_neighbor_bottom = skill_button.get_path()
	defend_button.focus_neighbor_top = skill_button.get_path()
	defend_button.focus_neighbor_bottom = run_button.get_path()
	skill_button.focus_neighbor_top = attack_button.get_path()
	skill_button.focus_neighbor_bottom = defend_button.get_path()
	run_button.focus_neighbor_top = defend_button.get_path()
	
	# Set initial focus
	attack_button.grab_focus()
	
	update_ui()
	hide_skill_menu()

func update_ui():
	player_health_label.text = "Player Health: " + str(GameData.player_health)
	enemy_health_label.text = "Enemy Health: " + str(enemy_health)

func show_skill_menu():
	skill_menu.visible = true
	hide_buttons()
	update_skill_list()
	
	if skill_list.get_child_count() > 0:
		skill_list.get_child(0).grab_focus()

func hide_skill_menu():
	skill_menu.visible = false
	show_buttons()
	skill_button.grab_focus()

func update_skill_list():
	# Clear existing skill buttons
	for child in skill_list.get_children():
		child.queue_free()
	
	# Create new skill buttons
	for skill in current_skills:
		var new_button = Button.new()
		new_button.text = skill.name + " (MP: " + str(skill.mp_cost) + ")"
		new_button.connect("pressed", Callable(self, "_on_skill_selected").bind(skill))
		new_button.get_theme_stylebox("normal").bg_color = Color.BLACK
		new_button.get_theme_stylebox("normal").border_width_left = 5
		new_button.get_theme_stylebox("normal").border_width_right = 5
		new_button.get_theme_stylebox("normal").border_color = Color.DODGER_BLUE
		# Disable button if not enough MP
		if GameData.player_mp < skill.mp_cost:
			new_button.disabled = true
		
		skill_list.add_child(new_button)

func _on_skill_selected(skill):
	if battle_state == BattleState.PLAYER_TURN:
		use_skill(skill)
		hide_skill_menu()
		end_turn()

func use_skill(skill):
	if GameData.player_mp >= skill.mp_cost:
		if skill.damage < 0:  # Healing skill
			var heal_amount = -skill.damage
			GameData.player_health += heal_amount
			if GameData.player_health > GameData.player_maxhealth:
				GameData.player_health = GameData.player_maxhealth
			battle_log.text = "You healed yourself for " + str(heal_amount) + " HP!"
		else:  # Damage skill
			var skill_damage = skill.damage
			damage = 100 * skill_damage / (100 + enemy_defense)
			enemy_health -= damage
			hit_flash_animation_enemy.play("hit_flash")
			battle_log.text = "You used " + skill.name + " for " + str(damage) + " damage!"
		
		# Apply status effect if the skill has one
		if skill.has("effect"):
			enemy_status_effects.append(skill.effect)
			battle_log.text += "\nEnemy is now affected by " + skill.effect.type + "!"
		
		GameData.player_mp -= skill.mp_cost
		update_ui()
	else:
		battle_log.text = "Not enough MP to use " + skill.name + "!"

func apply_status_effects():  # Missing in your code
	# Apply player status effects
	for effect in player_status_effects:
		match effect.type:
			"POISON":
				GameData.player_health -= effect.potency
				battle_log.text += "\nPlayer took " + str(effect.potency) + " poison damage!"
			"BURN":
				GameData.player_health -= effect.potency
				GameData.player_defense = max(GameData.player_defense - effect.potency, 0)
				battle_log.text += "\nPlayer took " + str(effect.potency) + " burn damage!"
			"STUN":
				battle_log.text += "\nPlayer is stunned!"
		effect.duration -= 1
	
	# Remove expired effects
	player_status_effects = player_status_effects.filter(func(effect): return effect.duration > 0)

	# Apply enemy status effects
	for effect in enemy_status_effects:
		match effect.type:
			"POISON":
				enemy_health -= effect.potency
				battle_log.text += "\nEnemy took " + str(effect.potency) + " poison damage!"
			"BURN":
				enemy_health -= effect.potency
				enemy_defense = max(enemy_defense - effect.potency, 0)
				battle_log.text += "\nEnemy took " + str(effect.potency) + " burn damage!"
			"STUN":
				battle_log.text += "\nEnemy is stunned!"
		effect.duration -= 1
	
	# Remove expired effects
	enemy_status_effects = enemy_status_effects.filter(func(effect): return effect.duration > 0)

func _on_back_pressed():
	show_buttons()
	hide_skill_menu()
	skill_button.grab_focus()

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
		
		show_skill_menu()
		back_button.grab_focus()

func _on_run_pressed():
	if battle_state == BattleState.PLAYER_TURN:
		run_away()

func attack():
	var player_damage = 50
	damage = 100 * player_damage / (100 + enemy_defense)
	enemy_health -= damage
	hit_flash_animation_enemy.play("hit_flash")
	battle_log.text = "You attacked the enemy for " + str(damage) + " damage!"
	update_ui()

func defend():
	player_defending = true
	battle_log.text = "You defend! Damage taken next turn will be reduced."

func run_away():
	battle_log.text = "You ran away!"
	emit_signal("battle_ended")

func enemy_turn():
	# Check if the enemy is stunned
	var is_stunned = false
	for effect in enemy_status_effects:
		if effect.type == "STUN":
			is_stunned = true
			break
	
	if is_stunned:
		battle_log.text = "Enemy is stunned and skips their turn!"
		enemy_status_effects = enemy_status_effects.filter(func(effect): return effect.type != "STUN" or effect.duration > 1)
		if enemy_status_effects.size() > 0:
			for effect in enemy_status_effects:
				if effect.type == "STUN":
					effect.duration -= 1
		battle_state = BattleState.PLAYER_TURN
		player_buttons()
		return  # Skip the enemy's turn
	
	# Apply status effects (e.g., poison, burn)
	apply_status_effects()
	
	# Enemy attacks
	if player_defending == true:
		damage = 100 * defense_damage / (100 + GameData.player_defense)
		GameData.player_health -= damage
		hit_flash_animation_player.play("hit_flash_player")
		battle_log.text = "Enemy attacks you for " + str(defense_damage) + " damage!"
	else:
		damage = 100 * enemy_damage / (100 + GameData.player_defense)
		GameData.player_health -= damage
		hit_flash_animation_player.play("hit_flash_player")
		battle_log.text = "Enemy attacks you for " + str(enemy_damage) + " damage!"
	
	update_ui()
	player_defending = false
	
	if GameData.player_health <= 0:
		await get_tree().create_timer(.4).timeout
		battle_start.play("Player_Dead")
		battle_log.text = "You have been defeated."
		await get_tree().create_timer(2.0).timeout
		emit_signal("battle_ended")
	
	battle_state = BattleState.PLAYER_TURN
	player_buttons()

func end_turn():
	if enemy_health <= 0:
		attack_button.visible = false
		skill_button.visible = false
		defend_button.visible = false
		run_button.visible = false
		
		attack_button.disabled = true
		skill_button.disabled = true
		defend_button.disabled = true
		run_button.disabled = true
		
		await get_tree().create_timer(.4).timeout
		battle_start.play("Enemy_Dead")
		
		battle_log.text = "You gained " + str(enemy_info.enemy_xp) + " XP!"
		GameData.xp_increase(enemy_info.enemy_xp)
		
		battle_log.text += "\nEnemy defeated!"
		await get_tree().create_timer(2.0).timeout
		emit_signal("battle_ended")
	else:
		battle_state = BattleState.ENEMY_TURN
		player_buttons()
		await get_tree().create_timer(2.0).timeout
		enemy_turn()

func player_buttons():
	if battle_state == BattleState.PLAYER_TURN:
		attack_button.grab_focus()
		show_buttons()
	elif battle_state == BattleState.ENEMY_TURN:
		hide_buttons()

func show_buttons():
	attack_button.visible = true
	skill_button.visible = true
	defend_button.visible = true
	run_button.visible = true
	
	attack_button.disabled = false
	skill_button.disabled = false
	defend_button.disabled = false
	run_button.disabled = false

func hide_buttons():
	attack_button.visible = false
	skill_button.visible = false
	defend_button.visible = false
	run_button.visible = false
	
	attack_button.disabled = true
	skill_button.disabled = true
	defend_button.disabled = true
	run_button.disabled = true

func end_battle():
	emit_signal("battle_ended")
	battle_log.text = "Battle ended!"
	get_tree().change_scene("res://Scenes/Main.tscn")
