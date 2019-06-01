extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite.playing = true


func _on_AnimatedSprite_animation_finished():
	self.queue_free()
