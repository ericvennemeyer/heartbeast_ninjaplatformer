class_name Hitbox extends Area2D

@export var damage := 1.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area_2d: Area2D) -> void:
	assert(area_2d is Hurtbox, "The Hitbox detected an area that is not a Hurtbox.")
	var hurtbox = area_2d as Hurtbox
	if hurtbox.is_invincible: return
	hurtbox.hurt.emit(self)
