extends Node2D

signal battle_ended

enum BattleState {
	PLAYER_TURN,
	ENEMY_TURN
}

var battle_state = BattleState.PLAYER_TURN
var enemies = []
var player_defense = 100
var damage
var player_defending = false
var defense_damage = null  # Initialize defense_damage to null

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

# Target selection UI
@onready var target_selection = $TargetSelection
@onready var target_buttons = $TargetSelection/VBoxContainer

# Textbox for battle events
@onready var battle_log = $CombatUI/BattleLog

# Party UI
@onready var party_ui = $PartyUI

# Player skills (loaded from GameData)
var current_skills = []

# Status effects
var player_status_effects = []
var enemy_status_effects = []

# Current acting party member
var current_actor = null

# Turn order
var turn_order = []
var current_turn_index = 0

func _ready():
	GameData.initialize_party()
	GameData.restore_party_state()
	battle_start.play("Battle_Start")
	
	enemies = enemy_info.get_enemies()
	
	camera.make_current()
	playeranim.play("Idle")
	
	# Load skills from GameData
	current_skills = GameData.current_party[0].skills  # Default to first party member's skills
	
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
	update_party_ui()
	
	# Initialize turn order
	initialize_turn_order()

func initialize_turn_order():
	# Add players to turn order
	for i in range(GameData.current_party.size()):
		turn_order.append({"type": "player", "index": i, "speed": GameData.current_party[i].speed})
	
	# Add enemies to turn order
	for i in range(enemies.size()):
		turn_order.append({"type": "enemy", "index": i, "speed": 50})  # Assuming enemies have a fixed speed of 50
	
	# Sort turn order by speed (highest speed goes first)
	turn_order.sort_custom(func(a, b): return a.speed > b.speed)
	
	current_turn_index = 0
	start_next_turn()

func start_next_turn():
	print("Starting next turn. Current turn index: ", current_turn_index)
	if is_battle_over():
		print("Battle is over. Stopping turn system.")
		return
	
	if current_turn_index >= turn_order.size():
		current_turn_index = 0
		print("Resetting turn order.")
	
	var current_turn = turn_order[current_turn_index]
	print("Current turn: ", current_turn.type, " index: ", current_turn.index)
	
	if current_turn.type == "player":
		print("Player's turn.")
		battle_state = BattleState.PLAYER_TURN
		current_actor = current_turn.index
		player_buttons()
	else:
		print("Enemy's turn.")
		battle_state = BattleState.ENEMY_TURN
		enemy_turn(current_turn.index)
	
	current_turn_index += 1

func update_ui():
	player_health_label.text = "Player Health: " + str(GameData.current_party[0].health)
	enemy_health_label.text = "Enemy Health: " + str(enemies[0].health)

func update_party_ui():
	for i in range(GameData.current_party.size()):
		var member = GameData.current_party[i]
		var panel = party_ui.get_child(i)
		
		panel.get_node("Name").text = member.name
		panel.get_node("Health").value = member.health
		panel.get_node("Health").max_value = member.max_health
		panel.get_node("MP").value = member.mp
		panel.get_node("MP").max_value = member.max_mp

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
		skill_list.add_child(new_button)

func _on_skill_selected(skill):
	if battle_state == BattleState.PLAYER_TURN:
		show_target_selection(skill)

func show_target_selection(skill=null):
	target_selection.visible = true
	for child in target_buttons.get_children():
		child.queue_free()
	
	for i in range(enemies.size()):
		var target_button = Button.new()
		target_button.text = "Enemy " + str(i + 1)
		target_button.connect("pressed", Callable(self, "_on_target_selected").bind(i, skill))
		target_buttons.add_child(target_button)
	
	target_buttons.get_child(0).grab_focus()

func _on_target_selected(target_index, skill=null):
	target_selection.visible = false
	if skill:
		use_skill(skill, target_index)
	else:
		attack(target_index)
	end_turn()

func use_skill(skill, target_index):
	if GameData.current_party[current_actor].mp >= skill.mp_cost:
		if skill.damage < 0:  # Healing skill
			var heal_amount = -skill.damage
			GameData.current_party[current_actor].health += heal_amount
			if GameData.current_party[current_actor].health > GameData.current_party[current_actor].max_health:
				GameData.current_party[current_actor].health = GameData.current_party[current_actor].max_health
			battle_log.text = "You healed yourself for " + str(heal_amount) + " HP!"
		else:  # Damage skill
			var skill_damage = skill.damage
			damage = 100 * skill_damage / (100 + enemies[target_index].defense)
			enemies[target_index].health -= damage
			hit_flash_animation_enemy.play("hit_flash")
			battle_log.text = "You used " + skill.name + " on Enemy " + str(target_index + 1) + " for " + str(damage) + " damage!"
		
		# Apply status effect if the skill has one
		if skill.has("effect"):
			enemy_status_effects.append(skill.effect)
			battle_log.text += "\nEnemy is now affected by " + skill.effect.type + "!"
		
		GameData.current_party[current_actor].mp -= skill.mp_cost
		update_ui()
		update_party_ui()
	else:
		battle_log.text = "Not enough MP to use " + skill.name + "!"

func apply_status_effects():
	# Apply player status effects
	for effect in player_status_effects:
		match effect.type:
			"POISON":
				GameData.current_party[current_actor].health -= effect.potency
				battle_log.text += "\nPlayer took " + str(effect.potency) + " poison damage!"
			"BURN":
				GameData.current_party[current_actor].health -= effect.potency
				GameData.current_party[current_actor].defense = max(GameData.current_party[current_actor].defense - effect.potency, 0)
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
				enemies[0].health -= effect.potency
				battle_log.text += "\nEnemy took " + str(effect.potency) + " poison damage!"
			"BURN":
				enemies[0].health -= effect.potency
				enemies[0].defense = max(enemies[0].defense - effect.potency, 0)
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
		show_target_selection()

func _on_defend_pressed():
	if battle_state == BattleState.PLAYER_TURN:
		defend()
		end_turn()

func _on_skill_pressed():
	if battle_state == BattleState.PLAYER_TURN:
		show_skill_menu()

func _on_run_pressed():
	if battle_state == BattleState.PLAYER_TURN:
		run_away()

func attack(target_index):
	var player_damage = 50
	damage = 100 * player_damage / (100 + enemies[target_index].defense)
	enemies[target_index].health -= damage
	hit_flash_animation_enemy.play("hit_flash")
	battle_log.text = "You attacked Enemy " + str(target_index + 1) + " for " + str(damage) + " damage!"
	update_ui()

func defend():
	player_defending = true
	# Calculate defense_damage based on the current enemy's damage
	defense_damage = enemies[0].damage / 2  # Assuming the first enemy is the one attacking
	battle_log.text = "You defend! Damage taken next turn will be reduced."

func run_away():
	battle_log.text = "You ran away!"
	GameData.save_party_state()
	emit_signal("battle_ended")

func enemy_turn(enemy_index):
	var target_index = randi_range(0, GameData.current_party.size() - 1)
	var target = GameData.current_party[target_index]
	
	print("Enemy damage: ", enemies[enemy_index].damage)
	print("Player defending: ", player_defending)
	print("Defense damage: ", defense_damage)
	
	if player_defending == true:
		if defense_damage == null:
			defense_damage = enemies[enemy_index].damage / 2
			print("Defense damage initialized to: ", defense_damage)
		
		damage = 100 * defense_damage / (100 + target.defense)
		damage = min(damage, defense_damage)  # Ensure damage doesn't exceed defense_damage
		target.health -= damage
		hit_flash_animation_player.play("hit_flash_player")
		battle_log.text = "Enemy attacks " + target.name + " for " + str(damage) + " damage!"
	else:
		damage = 100 * enemies[enemy_index].damage / (100 + target.defense)
		damage = min(damage, enemies[enemy_index].damage)  # Ensure damage doesn't exceed enemy's base damage
		target.health -= damage
		hit_flash_animation_player.play("hit_flash_player")
		battle_log.text = "Enemy attacks " + target.name + " for " + str(damage) + " damage!"
	
	# Ensure health doesn't go below 0
	target.health = max(target.health, 0)
	
	update_ui()
	update_party_ui()
	
	# Reset defending state
	player_defending = false
	defense_damage = null  # Reset defense_damage
	
	if target.health <= 0:
		battle_log.text += "\n" + target.name + " has been defeated!"
	
	# Wait for a short delay before starting the next turn
	await get_tree().create_timer(1.0).timeout  # Adjust the delay as needed
	
	# Start the next turn
	start_next_turn()

func is_battle_over():
	return all_enemies_defeated() or all_players_defeated()
	
func all_enemies_defeated():
	for enemy in enemies:
		if enemy.health > 0:
			return false
	return true
	
func all_players_defeated():
	for member in GameData.current_party:
		if member.health > 0:
			return false
	return true
		
func end_turn():
	if is_battle_over():
		return
		
	if all_enemies_defeated():
		battle_log.text = "You gained " + str(enemies[0].xp) + " XP!"
		GameData.xp_increase(enemies[0].xp)
		battle_log.text += "\nEnemy defeated!"
		await get_tree().create_timer(2.0).timeout
		GameData.save_party_state()
		emit_signal("battle_ended")
		return
		
	if all_players_defeated():
		battle_log.text = "You have been defeated."
		await get_tree().create_timer(2.0).timeout
		GameData.save_party_state()
		emit_signal("battle_ended")
		return
		
	start_next_turn()
	
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
