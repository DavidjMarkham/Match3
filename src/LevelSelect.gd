extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_LevelButton_level_selected(level_number):
	get_tree().change_scene("res://Scenes/levels/lvl" + str(level_number) + ".tscn")

