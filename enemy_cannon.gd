extends Node2D

@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		queue_free()
	)
