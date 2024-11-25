# GameData.gd
extends Node

# A variable to store the player's position
var player_position = Vector2.ZERO

var player_maxhealth = 100
var player_health = 100
var player_attack = 40
var player_defense = 80
var player_speed = 50

#PLAYER XP AND LEVEL
var player_level = 1
var max_xp = 100
var current_xp = 0
var xp

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
	
	print("HP + 50 = ", player_maxhealth)
	print("Attack + 30 = ", player_attack)
	print("Defense + 40 = ", player_defense)
	print("Speed + 20 = ", player_speed)
#____________________________________________
