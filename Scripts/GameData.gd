# GameData.gd
extends Node

# Player position
var player_position = Vector2.ZERO

# Player XP and level
var player_level = 1
var max_xp = 100
var current_xp = 0

# Party members data
var party_members = [
	{
		"name": "Hero",
		"health": 100,
		"max_health": 100,
		"mp": 50,
		"max_mp": 50,
		"attack": 40,
		"defense": 80,
		"speed": 50,
		"skills": [
			{"name": "Fireball", "damage": 80, "mp_cost": 10, "effect": {"type": "BURN", "duration": 3, "potency": 5}},
			{"name": "Heal", "damage": -50, "mp_cost": 15}
		]
	},
	{
		"name": "Mage",
		"health": 80,
		"max_health": 80,
		"mp": 100,
		"max_mp": 100,
		"attack": 30,
		"defense": 50,
		"speed": 40,
		"skills": [
			{"name": "Ice Shard", "damage": 60, "mp_cost": 8, "effect": {"type": "FREEZE", "duration": 2, "potency": 0}},
			{"name": "Thunder Strike", "damage": 70, "mp_cost": 12}
		]
	},
	{
		"name": "Warrior",
		"health": 120,
		"max_health": 120,
		"mp": 30,
		"max_mp": 30,
		"attack": 60,
		"defense": 100,
		"speed": 30,
		"skills": [
			{"name": "Slash", "damage": 50, "mp_cost": 10},
			{"name": "Defend", "damage": 0, "mp_cost": 5, "effect": {"type": "DEFENSE_BUFF", "duration": 2, "potency": 20}}
		]
	}
]

# Active party members in battle
var current_party = []

# Initialize the party
func initialize_party():
	if current_party.is_empty():  # Only initialize if the party is empty
		current_party = party_members.duplicate(true)  # Deep copy to avoid modifying original data
	print("Party initialized with ", current_party.size(), " members.")

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
	for member in current_party:
		member.max_health += 50
		member.health += 50
		member.attack += 30
		member.defense += 40
		member.speed += 20
		member.max_mp += 20
		member.mp = member.max_mp
	
	print("All party members leveled up!")
	print("HP + 50, Attack + 30, Defense + 40, Speed + 20, MP + 20")


func save_party_state():
	print("Saving party state...")
	for i in range(current_party.size()):
		party_members[i].health = current_party[i].health
		party_members[i].mp = current_party[i].mp
		print("Saved ", current_party[i].name, ": ", current_party[i].health, " HP, ", current_party[i].mp, " MP")

func restore_party_state():
	print("Restoring party state...")
	for i in range(party_members.size()):
		current_party[i].health = party_members[i].health
		current_party[i].mp = party_members[i].mp
		print("Restored ", current_party[i].name, ": ", current_party[i].health, " HP, ", current_party[i].mp, " MP")
