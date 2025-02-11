# StatusEffect.gd
extends Resource
class_name StatusEffect

enum EffectType {
	POISON,  # Deals damage over time
	BURN,    # Deals damage over time and reduces defense
	STUN,    # Skips turn
	BUFF_ATK,  # Increases attack
	BUFF_DEF   # Increases defense
}

@export var type: EffectType
@export var duration: int  # Number of turns the effect lasts
@export var potency: int   # Strength of the effect (e.g., damage amount, stat change)
