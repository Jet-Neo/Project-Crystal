extends Node2D


var enemy_ammount = 3
var enemy_damage = 0
var enemy_health = 0
var enemy_defense = 0


@onready var enemyanim = $"../Enemy"

func _ready():
	var random_enemy = randi_range(1, enemy_ammount)
	
	match random_enemy:
		1:
			print("Enemy 1")
			enemy_health = 200
			enemy_damage = 20
			enemy_defense = 120
			enemyanim.play("Idle")
		2:
			print("Enemy 2")
			enemy_health = 150
			enemy_damage = 30
			enemy_defense = 70
			enemyanim.play("Idle_2")
			
		3:
			print("Enemy 3")
			enemy_health = 80
			enemy_damage = 10
			enemy_defense = 50
			enemyanim.play("Idle_3")
		
		
func health():
	return enemy_health

func damage():
	return enemy_damage
	
func defense():
	return enemy_defense
