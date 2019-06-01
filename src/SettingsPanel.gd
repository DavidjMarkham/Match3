extends "res://src/BaseMenuPanel.gd"
signal sound_changed
signal back_button


func _on_Button1_pressed():
	emit_signal("sound_changed")


func _on_Button2_pressed():
	emit_signal("back_button")
