extends Node2D

@export var stats: Stats:
	set(value):
		stats = value
		if stats is not Stats: return
		stats = stats.duplicate()

@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		stats.health -= other_hitbox.damage
	)
	stats.no_health.connect(func(): 
		queue_free()
	)
