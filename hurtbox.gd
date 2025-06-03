class_name Hurtbox extends Area2D

@export var is_invincible: bool = false:
	set(value):
		is_invincible = value
		# Following code essentially "resets" collision shape so player can still take damage
		# if touching enemy after invincibility period ends
		var children = get_children()
		for child in children:
			if child is not CollisionShape2D and child is not CollisionPolygon2D:
				continue
			child.set_deferred("disabled", is_invincible)

signal hurt(other_hitbox: Hitbox)

func take_hit(other_hitbox: Hitbox) -> void:
	if is_invincible: return
	hurt.emit(other_hitbox)
