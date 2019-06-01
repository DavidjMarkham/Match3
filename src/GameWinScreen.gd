extends "res://src/BaseMenuPanel.gd"

var is_won = false


func _on_ContinueButton_pressed():
	get_tree().reload_current_scene()

func _on_GoalHolder_game_won():
	if(!self.is_won):
		self.slide_in()
		self.is_won = true
