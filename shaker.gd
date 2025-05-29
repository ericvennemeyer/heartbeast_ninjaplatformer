class_name Shaker extends RefCounted


var target: Node2D
var starting_postion: Vector2
var shakes: int = 4


func _init(new_target: Node2D) -> void:
	target = new_target
	starting_postion = target.position


func shake(amount: float, duration: float) -> void:
	for i in shakes:
		target.position = starting_postion + Vector2(randi_range(-amount, amount), randi_range(-amount, amount))
		await target.get_tree().create_timer(duration / amount).timeout
		amount -= (amount / shakes)
	target.position = starting_postion
