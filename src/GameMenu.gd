extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$Main.slide_in()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Main_settings_pressed():
	$Main.slide_out()
	$Settings.slide_in()


func _on_Settings_back_button():	
	$Settings.slide_out()
	$Main.slide_in()


func _on_Main_play_pressed():
	get_tree().change_scene("res://Scenes/levels/lvl1.tscn")
