extends CharacterBody2D

@export var speed: int = 50
@export var acceleration: int = 5
@export var jump_speed: int = -speed * 2.5
@export var gravity: int = speed * 5
@export var down_gravity_factor: float = 1.5
@export var health: int = 3

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_time_buffer: Timer = $JumpTimeBuffer
@onready var coyote_timer: Timer = $CoyoteTimer

enum State {IDLE,RUN,JUMP,DOWN}
var current_state: State = State.IDLE

var hasKey: bool = false

var knockback: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

func _physics_process(delta: float) -> void:
	handle_input()
	handle_knockback(delta)
	update_movement(delta)
	update_state()
	update_animation()
	move_and_slide()
	

func handle_input() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_time_buffer.start()
	
	var direction = Input.get_axis("move_left","move_right")
	
	if direction == 0:
		velocity.x = move_toward(velocity.x, 0 ,acceleration)
	else:
		velocity.x = move_toward(velocity.x, speed * direction, acceleration)

func update_movement(delta: float) -> void:
	if (is_on_floor() || coyote_timer.time_left > 0) && jump_time_buffer.time_left > 0:
		velocity.y = jump_speed
		current_state = State.JUMP
		jump_time_buffer.stop()
		coyote_timer.stop()
		
	if current_state == State.JUMP:
		velocity.y += gravity * delta
	else:
		velocity.y += gravity * down_gravity_factor * delta
	
func update_state() -> void:
	match current_state:
		State.IDLE when velocity.x != 0:
			current_state = State.RUN
			
		State.RUN:
			if velocity.x == 0:
				current_state = State.IDLE
			if not is_on_floor() && velocity.y > 0:
				current_state = State.DOWN
				coyote_timer.start()
		
		State.JUMP when velocity.y > 0:
			current_state = State.DOWN
		
		State.DOWN when is_on_floor():
			if velocity.x == 0:
				current_state = State.IDLE
			else:
				current_state = State.RUN


func update_animation() -> void:
	if velocity.x != 0:
		animation.scale.x = sign(velocity.x)
	
	match current_state:
		State.IDLE: animation.play("idle")
		State.RUN: animation.play("run")
		State.JUMP: animation.play("jump_up")
		State.DOWN: animation.play("jump_down")
	

func apply_knockback(direction: Vector2, force: float, knockback_duration: float) -> void:
	knockback = direction * force
	knockback_timer = knockback_duration
	
func handle_knockback(delta: float) -> void:
	if knockback_timer > 0.0:
		velocity.x = knockback.x
		velocity.y += knockback.y  # Gravity läuft weiter
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is TileMapLayer: # TileMap collision bodies sind StaticBody2D
		if body.name == "Enemie":
			# Spieler trifft Spike
			health -= 1
			print("Ouch! Health:", health)
			
			# Knockback-Richtung: aus Bewegungsrichtung
			var dir_x = -sign(velocity.x)
			var dir_y = -sign(velocity.y)
			if dir_x == 0:
				dir_x = -1  
			if dir_y == 0:
				dir_y = 0  
				
			var knock_dir = Vector2(dir_x, dir_y).normalized()
			apply_knockback(knock_dir, 150.0, 0.02)
			return
		if body.name == "Door" && hasKey == false:
			print("Needkey")
			return
		if body.name == "Door" && hasKey == true:
			print("Yey")
			return

	if body is key:
		print("key is pickedup")
		hasKey = true
		body.pickUp()
