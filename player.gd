extends CharacterBody2D

enum States { MOVE, CLIMB, HIT }

@export var stats: Stats
@export var state = States.MOVE

@export var max_speed := 120
@export var acceleration := 10000
@export var air_acceleration := 2000
@export var friction := 10000
@export var air_friction := 500
@export var up_gravity := 500
@export var down_gravity := 600
@export var jump_amount := 200

var coyote_time := 0.0

@onready var anchor: Node2D = $Anchor
@onready var sprite_upper: Sprite2D = $Anchor/SpriteUpper
@onready var sprite_lower: Sprite2D = $Anchor/SpriteLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var effects_animation_player: AnimationPlayer = $EffectsAnimationPlayer
@onready var ray_cast_upper: RayCast2D = $Anchor/RayCastUpper
@onready var ray_cast_lower: RayCast2D = $Anchor/RayCastLower
@onready var hurtbox: Hurtbox = $Anchor/Hurtbox
@onready var shaker_upper: Shaker = Shaker.new(sprite_upper)
@onready var shaker_lower: Shaker = Shaker.new(sprite_lower)
@onready var camera_2d: Camera2D = $Camera2D


func _ready() -> void:
	sprite_lower.material.set_shader_parameter("flash_color", Color("ff4d4d"))
	
	stats.no_health.connect(func():
		camera_2d.reparent(get_tree().current_scene)
		queue_free()
		)
	
	animation_player_lower.current_animation_changed.connect(func(anim_name: String):
		if animation_player_upper.current_animation == "attack": return
		animation_player_upper.play(anim_name)
		)
	animation_player_upper.animation_finished.connect(func(anim_name: String):
		if anim_name != "attack": return
		animation_player_upper.play(animation_player_lower.current_animation)
		animation_player_upper.seek(animation_player_lower.current_animation_position)
		)
	
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		# Knockback
		var x_direction = sign(other_hitbox.global_position.direction_to(global_position).x)
		if x_direction == 0: x_direction = -1
		velocity.x = x_direction * max_speed
		jump(jump_amount / 2)
		# Enter HIT state so input won't be processed
		state = States.HIT
		# Shake player sprites
		shaker_upper.shake(3.0, 0.3)
		shaker_lower.shake(3.0, 0.3)
		# Make sure we're in the jump animation while in HIT state
		animation_player_lower.play("jump")
		# Play flash animation, which also sets is_invincible back to false, and state back to MOVE
		effects_animation_player.play("hitflash")
		# Subtract damage dealt by enemy from player health
		stats.health -= other_hitbox.damage
		)


func _physics_process(delta: float) -> void:
	coyote_time -= delta
	
	match state:
		States.MOVE:
			var x_input = Input.get_axis("move_left", "move_right")
			
			apply_gravity(delta)
			
			if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_time > 0):
				jump()
			
			if Input.is_action_just_pressed("attack"):
				animation_player_upper.play("attack")
			
			if x_input == 0:
				apply_friction(delta)
				animation_player_lower.play("stand")
			else:
				accelerate_horizontally(x_input, delta)
				anchor.scale.x = sign(x_input)
				animation_player_lower.play("run")
			
			if not is_on_floor():
				animation_player_lower.play("jump")
			
			var was_on_floor := is_on_floor()
			
			move_and_slide()
			
			if was_on_floor and not is_on_floor() and velocity.y >= 0:
				coyote_time = 0.1
			
			if should_wall_climb():
				animation_player_upper.play("hang")
				state = States.CLIMB
			
		States.CLIMB:
			var wall_normal = get_wall_normal()
			
			var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			
			velocity.y = input.y * max_speed * 0.8
			
			move_and_slide()
			
			if input.y == 0:
				animation_player_lower.play("hang")
			else:
				animation_player_lower.play("climb")
			
			var request_detach: bool = sign(input.x) == wall_normal.x
			
			var request_wall_jump: bool = (
				(request_detach or Input.is_action_just_pressed("jump"))
				and not Input.is_action_pressed("move_down")
			)
			
			if request_wall_jump:
				velocity.x = wall_normal.x * max_speed
				anchor.scale.x = sign(velocity.x)
				jump()
				state = States.MOVE
			
			if not should_wall_climb() or request_detach:
				if Input.is_action_pressed("move_up"):
					jump()
				state = States.MOVE
		
		States.HIT:
			move_and_slide()
			apply_friction(delta)
			apply_gravity(delta)


func jump(amount: = jump_amount) -> void: # This syntax sets a default value for the argument "amount"
	velocity.y = -amount


func accelerate_horizontally(horizontal_direction: float, delta: float) -> void:
	var acceleration_amount := acceleration
	if not is_on_floor():
		acceleration_amount = air_acceleration
	velocity.x = move_toward(velocity.x, max_speed * horizontal_direction, acceleration_amount * delta)


func apply_friction(delta) -> void:
	var friction_amount := friction
	if not is_on_floor():
		friction_amount = air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction_amount * delta)


func apply_gravity(delta) -> void:
	if not is_on_floor():
		if velocity.y <= 0:
			velocity.y += up_gravity * delta
		else:
			velocity.y += down_gravity * delta


func should_wall_climb() -> bool:
	return (
		ray_cast_upper.is_colliding()
		and ray_cast_lower.is_colliding()
		and not is_on_floor()
	)
