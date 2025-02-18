extends Node2D

var enemy_amount = 3
var enemies = []

@onready var enemyanim = $"../Enemy"

func _ready():
	var random_enemy_count = randi_range(1, 3)  # Random number of enemies (1 to 3)
	for i in range(random_enemy_count):
		var random_enemy = randi_range(1, enemy_amount)
		var enemy = {
			"health": 0,
			"damage": 0,
			"defense": 0,
			"xp": 0,
			"anim": ""
		}
		
		match random_enemy:
			1:
				enemy.health = 200
				enemy.damage = 20
				enemy.defense = 100
				enemy.xp = 100
				enemy.anim = "Idle"
			2:
				enemy.health = 150
				enemy.damage = 30
				enemy.defense = 50
				enemy.xp = 70
				enemy.anim = "Idle_2"
			3:
				enemy.health = 80
				enemy.damage = 10
				enemy.defense = 20
				enemy.xp = 50
				enemy.anim = "Idle_3"
		
		enemies.append(enemy)
	
	# Play animations for each enemy (assuming you have animations set up)
	for i in range(enemies.size()):
		enemyanim.play(enemies[i].anim)

func get_enemies():
	return enemies

func health(index):
	return enemies[index].health

func damage(index):
	return enemies[index].damage

func defense(index):
	return enemies[index].defense

func xp(index):
	return enemies[index].xp
