extends StaticBody2D
class_name Door

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

const FILE_BEGIN = "res://Sceanes/Level/level_"

func open():
	animated_sprite_2d.play("open")
	timer.start()


func _on_timer_timeout() -> void:
	var current_sceane = get_tree().current_scene.scene_file_path
	var next_level_number = current_sceane.to_int() + 1
	var next_level_path = FILE_BEGIN + str(next_level_number) + ".tscn"
	get_tree().change_scene_to_file(next_level_path)
