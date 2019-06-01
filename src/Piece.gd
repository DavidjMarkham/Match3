extends Node2D

export (String) var color;
export (Texture) var row_texture
export (Texture) var col_texture
export (Texture) var adjacent_texture
export (Texture) var color_bomb_texture

var move_tween
var matched = false

var is_row_bomb = false
var is_column_bomb = false
var is_adjacent_bomb = false
var is_color_bomb = false

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween = $move_tween

func move(target):
	move_tween.interpolate_property(self,"position",position,target,.3,Tween.TRANS_ELASTIC,Tween.EASE_OUT);	
	move_tween.start()

func make_column_bomb():
	self.is_column_bomb = true
	$Sprite.texture = col_texture
	$Sprite.modulate = Color(1,1,1,1)

func make_row_bomb():
	self.is_row_bomb = true
	$Sprite.texture = row_texture
	$Sprite.modulate = Color(1,1,1,1)

func make_adjacent_bomb():
	self.is_adjacent_bomb = true
	$Sprite.texture = adjacent_texture
	$Sprite.modulate = Color(1,1,1,1)
	
func make_color_bomb():
	self.is_color_bomb = true
	$Sprite.texture = color_bomb_texture
	$Sprite.modulate = Color(1,1,1,1)
	self.color = "Color"

func dim():
	$Sprite.modulate = Color(1,1,1,.5)