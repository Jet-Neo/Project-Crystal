# GameData.gd
extends Node

# Player stats
var player_position = Vector2.ZERO
var player_maxhealth = 100
var player_health = 100
var player_attack = 40
var player_defense = 80
var player_speed = 50

# Player XP and level
var player_level = 1
var max_xp = 100
var current_xp = 0
var xp

# Player MP
var player_maxmp = 100
var player_mp = 100

# Player skills
var player_skills = [
	{"name": "Fireball", "damage": 80, "mp_cost": 10},
	{"name": "Ice Shard", "damage": 60, "mp_cost": 8},
	{"name": "Heal", "damage": -20, "mp_cost": 15},
	{"name": "Poison Dart", "damage": 20, "mp_cost": 12, "effect": {"type": "POISON", "duration": 3, "potency": 10}},
	{"name": "Stun Strike", "damage": 30, "mp_cost": 15, "effect": {"type": "STUN", "duration": 1, "potency": 0}}
]

# Add a new skill to the player's skill list
func add_skill(skill_name: String, skill_damage: int, skill_mp_cost: int, effect: Dictionary = {}):
	var new_skill = {
		"name": skill_name,
		"damage": skill_damage,
		"mp_cost": skill_mp_cost
	}
	if effect:
		new_skill["effect"] = effect
	player_skills.append(new_skill)

# Remove a skill from the player's skill list
func remove_skill(skill_name: String):
	for i in range(player_skills.size()):
		if player_skills[i].name == skill_name:
			player_skills.remove_at(i)
			break

# Level up and increase stats
func xp_increase(xp):
	current_xp += xp
	
	if current_xp >= max_xp:
		player_level += 1
		current_xp -= max_xp
		max_xp = 100 * pow(player_level, 1.5)
		print("YOU ARE NOW LEVEL ", player_level, " AND YOUR MAX XP IS NOW %.0f" % max_xp)
		
		level_up()

func level_up():
	player_maxhealth += 50
	player_health += 50
	player_attack += 30
	player_defense += 40
	player_speed += 20
	player_maxmp += 20
	player_mp = player_maxmp  # Restore MP on level up
	
	print("HP + 50 = ", player_maxhealth)
	print("Attack + 30 = ", player_attack)
	print("Defense + 40 = ", player_defense)
	print("Speed + 20 = ", player_speed)
	print("MP + 20 = ", player_maxmp)
