extends "res://src/BaseMenuPanel.gd"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.




func _on_QuitButton_pressed():
	get_tree().change_scene("res://Scenes/GameMenu.tscn")


func _on_RestartButton_pressed():
	get_tree().reload_current_scene()


func _on_grid_game_over():	
	self.slide_in()
