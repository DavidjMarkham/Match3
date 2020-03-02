extends Control

signal level_selected
export (int) var level_number 

# Called when the node enters the scene tree for the first time.
func _ready():
	$TextureButton/Label.text = str(level_number)


func _on_TextureButton_pressed():
	emit_signal("level_selected",level_number)
