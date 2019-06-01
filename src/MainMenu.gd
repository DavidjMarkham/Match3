extends "res://src/BaseMenuPanel.gd"
signal play_pressed
signal settings_pressed


func _on_Button1_pressed():
	emit_signal("play_pressed")


func _on_Button2_pressed():
	emit_signal("settings_pressed")
