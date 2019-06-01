extends Node2D

signal remove_lock

var lock_pieces = []
var width = 8
var height = 10
var licorice = preload("res://Scenes/licorice.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func make_2d_array():
	var array = [];
	for i in width:
		array.append([]);
		for j in height:
			array[i].append(null); 
	return array

func _on_grid_make_lock(board_position):			
	if(lock_pieces.size() == 0):
		lock_pieces = make_2d_array()
	var current = licorice.instance()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64, -board_position.y * 64 + 800)
	lock_pieces[board_position.x][board_position.y] = current

func _on_grid_damage_lock(board_position):
	if(lock_pieces.size() != 0):
		if(lock_pieces[board_position.x][board_position.y] != null):
			lock_pieces[board_position.x][board_position.y].take_damage(1)
			if(lock_pieces[board_position.x][board_position.y].health <= 0):
				lock_pieces[board_position.x][board_position.y].queue_free()
				lock_pieces[board_position.x][board_position.y] = null
				emit_signal("remove_lock",board_position)


