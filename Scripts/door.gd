extends StaticBody2D
class_name Door

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func open():
	print("Opened!")
	animated_sprite_2d.play("open")
