extends CharacterBody2D

@export var speed: int = 50
@export var acceleration: int = 5
@export var jump_speed: int = -speed * 2.5
@export var jump_amout: int = 2
@export var gravity: int = speed * 5
@export var down_gravity_factor: float = 1.5
@export var health: int = 3

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var h_container: HBoxContainer = $HUD/Control/HBoxContainer
@onready var heart_sceane: PackedScene = preload("res://Sceanes/heart.tscn")

#Timer 
@onready var jump_time_buffer: Timer = $JumpTimeBuffer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var timer: Timer = $Timer


enum State {IDLE,RUN,JUMP,DOWN}
var current_state: State = State.IDLE

var hasKey: bool = false

var knockback: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

var hearts_list: Array[TextureRect]
var jumps_left: int

func _ready() -> void:
	jumps_left = jump_amout
	for heart in health:
		var heart_temp = heart_sceane.instantiate()
		hearts_list.append(heart_temp)
		h_container.add_child(heart_temp)
	
	# Connect the coyote timer's timeout signal to our new function
	coyote_timer.timeout.connect(_on_coyote_timer_timeout)

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
	if jump_time_buffer.time_left > 0 and jumps_left > 0:
		velocity.y = jump_speed
		current_state = State.JUMP
		jumps_left -= 1
		jump_time_buffer.stop()
		coyote_timer.stop()
		
	if velocity.y > 0:
		velocity.y += gravity * down_gravity_factor * delta
	else:
		velocity.y += gravity * delta
	
func update_state() -> void:
	match current_state:
		State.IDLE when velocity.x != 0:
			current_state = State.RUN
			
		State.RUN:
			if velocity.x == 0:
				current_state = State.IDLE
			if not is_on_floor() and velocity.y > 0:
				current_state = State.DOWN
				coyote_timer.start()
		
		State.JUMP when velocity.y > 0:
			current_state = State.DOWN
		
		State.DOWN when is_on_floor():
			jumps_left = jump_amout
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
		velocity.y += knockback.y
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO

func update_heart_dispaly():
	for i in range(hearts_list.size()):
		if i >= health:
			hearts_list[i].get_child(0).play("noHeart")  

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		if body.name == "Enemie":
			health -= 1
			update_heart_dispaly()
			
			var dir_x = -sign(velocity.x) if velocity.x != 0 else -1
			var dir_y = -sign(velocity.y)
				
			var knock_dir = Vector2(dir_x, dir_y).normalized()
			apply_knockback(knock_dir, 150.0, 0.02)
			return

	if body is Key:
		print("key is pickedup") #ToDo Key Pickup display
		hasKey = true
		body.pickUp()

	if body is Door && hasKey:
		body.open()
		hasKey = false
		timer.start()

# This new function is called when the CoyoteTimer runs out.
func _on_coyote_timer_timeout() -> void:
	# If the player just fell off a ledge (jumps_left is at max)
	# and didn't use the coyote time jump, they lose that ground jump.
	if jumps_left == jump_amout:
		jumps_left -= 1


func _on_timer_timeout() -> void:
	scale *= 0.9 # shrink by 10% each second
	timer.start() # restart if you want continuous shrinking
