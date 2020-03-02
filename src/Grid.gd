extends Node2D

export (int) var width;
export (int) var height;
export (int) var x_start;
export (int) var y_start;
export (int) var offset;

# Obtsacles
export (PoolVector2Array) var empty_spaces
export (PoolVector2Array) var ice_spaces
export (PoolVector2Array) var lock_spaces
export (PoolVector2Array) var concrete_spaces
export (PoolVector2Array) var slime_spaces


# Obtsacle Signals
signal damage_ice
signal make_ice
signal damage_lock
signal make_lock
signal damage_concrete
signal make_concrete
signal damage_slime
signal make_slime

var damaged_slime = false
var all_pieces = []
var current_matches = []
var initial_fill = true

var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)
var controlling = false
var y_offset = 2

# Swap back variables
var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

# Sinker Variables
export (PackedScene) var sinker_piece
export (bool) var sinkers_in_scene
export (int) var max_sinkers
var current_sinkers = 0

# Scoring variables
signal update_score
signal setup_max_score
export (int) var piece_value
export (int) var max_score

var streak = 1

# Counter Variables
signal update_counter
export(int) var current_counter_value
export(bool) var is_moves
signal game_over

# Goals
signal check_goal

var color_bomb_used = false

# Effects
var particle_effect = preload("res://Scenes/ParticleEffect.tscn")
var animated_effect = preload("res://Scenes/AnimatedExplosion.tscn")

enum {wait, move}
var state

# Sounds
var tap_sfx 
var basic_sfx
var better_sfx
var best_sfx 


var possible_pieces = [
	preload("res://Scenes/yellow_piece.tscn"),
	preload("res://Scenes/blue_piece.tscn"),
	preload("res://Scenes/pink_piece.tscn"),
	preload("res://Scenes/orange_piece.tscn"),
	preload("res://Scenes/green_piece.tscn"),
	preload("res://Scenes/purple_piece.tscn")
];

# Called when the node enters the scene tree for the first time.
func _ready():
	# Load sounds
	tap_sfx = load("res://Assets/Audio/MatchTap.ogg")	 
	tap_sfx.set_loop(false)
	basic_sfx = load("res://Assets/Audio/MatchBasic.ogg")	 
	basic_sfx.set_loop(false)
	better_sfx = load("res://Assets/Audio/MatchBetter.ogg")	 
	better_sfx.set_loop(false)
	best_sfx = load("res://Assets/Audio/MatchBest.ogg")	 
	best_sfx.set_loop(false)
	randomize()
	self.all_pieces = self.make_2d_array();
	if(sinkers_in_scene):
		self.spawn_sinker(self.max_sinkers)
	self.spawn_pieces()
	self.spawn_ice()
	self.spawn_locks()
	self.spawn_concrete()
	self.spawn_slime()
	self.state = move
	emit_signal("update_counter",self.current_counter_value)
	emit_signal("setup_max_score",self.max_score)
	if(!self.is_moves):
		$Timer.start()
	
func restricted_fill(place):
	# Check empty pieces	
	return (is_in_array(empty_spaces,place) || is_in_array(concrete_spaces,place) || is_in_array(slime_spaces,place))
	
func restricted_move(place):
	# Check empty pieces	
	return is_in_array(lock_spaces,place)
	
func is_in_array(array,item):
	for i in array.size():
		if(array[i] == item):
			return true
	return false

func _process(delta):
	if(self.state == move):
		self.touch_input()


func make_2d_array():
	var array = [];
	for i in width:
		array.append([]);
		for j in height:
			array[i].append(null); 
	return array
	
func spawn_pieces():
	if(!self.initial_fill):
		self.streak+=1
	if(self.current_sinkers < self.max_sinkers):
		self.spawn_sinker(self.max_sinkers - self.current_sinkers)
		
	for i in width:
		for j in height:			
			if(self.is_piece_null(i,j) && !restricted_fill(Vector2(i,j))):
				# Grab random piece
				var rand = floor(rand_range(0,possible_pieces.size()));
				var piece = possible_pieces[rand].instance();
				var loops = 0
				while(match_at(i,j,piece.color) && loops < 100):
					rand = floor(rand_range(0,possible_pieces.size()));
					loops += 1
					piece = possible_pieces[rand].instance();
				
				add_child(piece);
				piece.position = self.grid_to_pixel(i,j - self.y_offset);
				piece.move(self.grid_to_pixel(i,j))
				self.all_pieces[i][j] = piece;
	self.after_refill()
	
func spawn_ice():
	for i in ice_spaces.size():	
		emit_signal("make_ice",ice_spaces[i])

func spawn_locks():
	for i in lock_spaces.size():	
		emit_signal("make_lock",lock_spaces[i])
		
func spawn_concrete():
	for i in concrete_spaces.size():	
		emit_signal("make_concrete",concrete_spaces[i])
		
func spawn_slime():
	for i in slime_spaces.size():	
		emit_signal("make_slime",slime_spaces[i])
	
func spawn_sinker(number_to_spawn):
	for i in number_to_spawn:
		var column = floor(rand_range(0,width))
		while(self.all_pieces[column][height-1] != null || self.restricted_fill(Vector2(column,height-1))):
			column = floor(rand_range(0,width))
		var current = sinker_piece.instance()
		self.add_child(current)
		current.position = self.grid_to_pixel(column,height - 1)
		self.all_pieces[column][height-1] = current
		current_sinkers+=1
	
func is_piece_sinker(column,row):
	if(self.all_pieces[column][row] != null):
		if(self.all_pieces[column][row].color == "None"):
			return true
	return false
	
func touch_input():
	if(Input.is_action_just_pressed("ui_touch")):
		if(self.is_in_grid(self.pixel_to_grid(get_global_mouse_position()))):
			first_touch = self.pixel_to_grid(get_global_mouse_position())
			controlling = true
	if(Input.is_action_just_released("ui_touch")):
		if(controlling): # && self.is_in_grid(self.pixel_to_grid(get_global_mouse_position()))):
			controlling = false
			final_touch = self.pixel_to_grid(get_global_mouse_position())
			self.touch_difference(first_touch,final_touch)
			
func swap_pieces(column,row,direction):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if(first_piece==null):
		return
	if(other_piece==null):
		return
	var first_piece_wr = weakref(first_piece)
	var other_piece_wr = weakref(other_piece)
	if(!first_piece_wr.get_ref()):
		return
	if(!other_piece_wr.get_ref()):
		return
	if(first_piece!=null && other_piece!=null && !self.restricted_move(Vector2(column,row)) && !self.restricted_move(Vector2(column,row) + direction)):		
		if(self.is_color_bomb(first_piece,other_piece)):
			if(first_piece.color == "Color" && other_piece.color == "Color"):
				self.clear_board()
			if(is_piece_sinker(column,row) || is_piece_sinker(column+direction.x,row+direction.y)):
				swap_back()
				return
			if(first_piece.color == "Color" && other_piece.color == "Color"):
				self.clear_board()
				self.match_color(first_piece.color)
				self.add_to_array(Vector2(column,row))
				self.match_and_dim(other_piece)
				self.add_to_array(Vector2(column + direction.x,row+direction.y))
			elif(first_piece.color == "Color"):
				self.match_color(other_piece.color)
				self.match_and_dim(other_piece)
				self.add_to_array(Vector2(column + direction.x,row+direction.y))
			elif(other_piece.color == "Color"):
				self.match_color(first_piece.color)
				self.add_to_array(Vector2(column,row))
		self.store_info(first_piece,other_piece,Vector2(column,row),direction)
		self.state = wait
		all_pieces[column][row] = other_piece
		all_pieces[column + direction.x][row + direction.y] = first_piece
		first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
		other_piece.move(grid_to_pixel(column,row))
		if(!self.move_checked):
			self.find_matches()
	
func is_color_bomb(piece_one,piece_two):
	if(piece_one.color == "Color" || piece_two.color == "Color"):
		self.color_bomb_used = true
		return true
	return false
		

func touch_difference(grid_1,grid_2):
	var difference = grid_2 - grid_1
	if(abs(difference.x) > abs(difference.y)):
		if(difference.x > 0):
			self.swap_pieces(grid_1.x,grid_1.y,Vector2(1,0))
		elif(difference.x < 0):
			self.swap_pieces(grid_1.x,grid_1.y,Vector2(-1,0))
	elif(abs(difference.y) > abs(difference.x)):
		if(difference.y > 0):
			self.swap_pieces(grid_1.x,grid_1.y,Vector2(0,1))
		elif(difference.y < 0):
			self.swap_pieces(grid_1.x,grid_1.y,Vector2(0,-1))
			

	
func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction
	
	
func swap_back():	
	# Move previously swapped pieces back to previous place	
	if(piece_one != null && piece_two != null):
		self.swap_pieces(last_place.x,last_place.y,last_direction)
	self.move_checked = false
	self.state = move
	
	
	
		
func match_at(i, j, color):
	if(i>1):
		if(!self.is_piece_null(i-1,j) && !self.is_piece_null(i-2,j)):
			if(self.all_pieces[i-1][j].color == color && self.all_pieces[i-2][j].color == color):
				return true
	if(j>1):		
		if(!self.is_piece_null(i,j-1) && !self.is_piece_null(i,j-2)):
			if(self.all_pieces[i][j-1].color == color && self.all_pieces[i][j-2].color == color):
				return true
			

func grid_to_pixel(column, row):
	var new_x = x_start + offset * column;
	var new_y = y_start - offset * row;
	return Vector2(new_x,new_y);


func pixel_to_grid(cur_pos):
	var new_x = round((cur_pos.x - x_start) / offset);
	var new_y = round((cur_pos.y - y_start) /-offset);
	if(new_x<0):
		new_x = 0
	if(new_x>self.width):
		new_x = width-1
		
	if(new_y<0):
		new_y = 0
	if(new_y>self.height):
		new_y = height-1
	
	return Vector2(new_x,new_y);	
	
func is_in_grid(grid_position):
	if(grid_position.x >= 0 && grid_position.x < width):
		
		if(grid_position.y>=0 && grid_position.y<height):
			
			return true
	return false
	
func find_matches():
	var match_found = false
	for i in width:
		for j in height:
			if(!self.is_piece_null(i,j) && !self.is_piece_sinker(i,j)):
				var current_color = self.all_pieces[i][j].color
				if(i>0 && i<width -1):
					if(!self.is_piece_null(i-1,j) && !self.is_piece_null(i+1,j)):
						if(self.all_pieces[i-1][j].color == current_color && self.all_pieces[i+1][j].color == current_color):
							match_found = true
							self.match_and_dim(self.all_pieces[i-1][j])
							self.match_and_dim(self.all_pieces[i][j])
							self.match_and_dim(self.all_pieces[i+1][j])
							self.add_to_array(Vector2(i-1,j))
							self.add_to_array(Vector2(i,j))
							self.add_to_array(Vector2(i+1,j))
				if(j>0 && j<height -1):
					if(!self.is_piece_null(i,j-1) && !self.is_piece_null(i,j+1)):
						if(self.all_pieces[i][j-1].color == current_color && self.all_pieces[i][j+1].color == current_color):
							match_found = true
							self.match_and_dim(self.all_pieces[i][j-1])
							self.match_and_dim(self.all_pieces[i][j])
							self.match_and_dim(self.all_pieces[i][j+1])
							self.add_to_array(Vector2(i,j-1))
							self.add_to_array(Vector2(i,j))
							self.add_to_array(Vector2(i,j+1))
							
	
	if(match_found):		
		if(!get_tree().get_root().get_node("game_window/AudioStreamPlayer").playing || 
			get_tree().get_root().get_node("game_window/AudioStreamPlayer").stream == tap_sfx ||
			get_tree().get_root().get_node("game_window/AudioStreamPlayer").stream == basic_sfx):
				if(self.streak <=1):
					get_tree().get_root().get_node("game_window/AudioStreamPlayer").stream = tap_sfx
				else: 
					get_tree().get_root().get_node("game_window/AudioStreamPlayer").stream = basic_sfx					
				get_tree().get_root().get_node("game_window/AudioStreamPlayer").play()	    
	
	self.get_bombed_pieces()
	get_parent().get_node("destroy_timer").start()
	
func get_bombed_pieces():
	for i in width:
		for j in height:
			if(self.all_pieces[i][j]!=null):
				if(self.all_pieces[i][j].matched):
					if(self.all_pieces[i][j].is_column_bomb):
						self.match_all_in_column(i)
					elif(self.all_pieces[i][j].is_row_bomb):
						self.match_all_in_row(j)
					elif(self.all_pieces[i][j].is_adjacent_bomb):
						self.find_adjacent_pieces(i,j)
						
func add_to_array(value,array_to_add=self.current_matches):
	if(!array_to_add.has(value)):
		array_to_add.append(value)
		
func find_bombs():
	if(self.color_bomb_used):
		return
	for i in current_matches.size():
		var cur_col = current_matches[i].x
		var cur_row = current_matches[i].y
		var cur_color = self.all_pieces[cur_col][cur_row].color
		var col_matched = 0
		var row_matched = 0
		var made_bomb = false		
		
		for j in current_matches.size():
			var this_col = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = self.all_pieces[this_col][this_row].color
			if(this_col == cur_col && cur_color == this_color):
				col_matched += 1
			if(this_row == cur_row && cur_color == this_color):
				row_matched += 1
		if((col_matched == 5 || row_matched == 5)  && cur_color != "Color"):
			self.make_bomb(3,cur_color)
			made_bomb = true
			continue
		if(col_matched == 3 && row_matched == 3 && cur_color != "Color"):
			self.make_bomb(0,cur_color)
			made_bomb = true
			continue
		if(row_matched == 4 && cur_color != "Color"):
			self.make_bomb(1,cur_color)
			made_bomb = true
			continue
		if(col_matched == 4 && cur_color != "Color"):
			self.make_bomb(2,cur_color)
			made_bomb = true
			continue
			
			
		
func make_bomb(bomb_type,color):
	for i in current_matches.size():
		var cur_col = current_matches[i].x
		var cur_row = current_matches[i].y
		if(self.all_pieces[cur_col][cur_row] == piece_one && piece_one.color == color):
			self.damage_special(cur_col,cur_row)
			emit_signal("check_goal",piece_one.color)
			piece_one.matched = false
			self.change_bomb(bomb_type,piece_one)
		if(self.all_pieces[cur_col][cur_row] == piece_two && piece_two.color == color):
			self.damage_special(cur_col,cur_row)
			emit_signal("check_goal",piece_two.color)
			piece_two.matched = false
			self.change_bomb(bomb_type,piece_one)
			
func change_bomb(bomb_type,piece):
	if(piece == null):		
		return
	var piece_wr = weakref(piece)
	if(!piece_wr.get_ref()):
		return
		
	get_tree().get_root().get_node("game_window/AudioStreamPlayer").stream = better_sfx			
	get_tree().get_root().get_node("game_window/AudioStreamPlayer").play()	    
	if(bomb_type == 0):
		piece.make_adjacent_bomb()
	elif(bomb_type == 1):
		piece.make_row_bomb()
	elif(bomb_type == 2):
		piece.make_column_bomb()
	elif(bomb_type == 3):
		piece.make_color_bomb()
		
func is_piece_null(column,row):
	return (all_pieces[column][row]==null)		
	
func match_and_dim(item):
	item.matched = true
	item.dim()

func destroy_matched():		
	self.find_bombs()			
	var was_matched = false
	for i in width:
		for j in height:
			if(!self.is_piece_null(i,j)):
				if(all_pieces[i][j].matched):
					emit_signal("check_goal",self.all_pieces[i][j].color)
					self.damage_special(i,j)
					was_matched = true
					self.all_pieces[i][j].queue_free()
					self.all_pieces[i][j] = null
					self.make_effect(particle_effect,i,j)
					self.make_effect(animated_effect,i,j)
					emit_signal("update_score",self.piece_value * streak)
					
	self.move_checked = true
	if(was_matched):
		get_parent().get_node("collapse_timer").start()
	else:
		self.swap_back()
	self.current_matches.clear()

func make_effect(effect,column, row):
	var current = effect.instance()
	current.position = self.grid_to_pixel(column,row)
	add_child(current)
		
func check_concrete(column, row):
	# Check right
	if(column<width -1):
		emit_signal("damage_concrete",Vector2(column + 1, row))				
	# Check left
	if(column>0):
		emit_signal("damage_concrete",Vector2(column - 1, row))
	# Check up
	if(row<height - 1):
		emit_signal("damage_concrete",Vector2(column, row+1))
	# Check down
	if(row>0):
		emit_signal("damage_concrete",Vector2(column, row-1))
		
func check_slime(column, row):
	# Check right
	if(column<width -1):
		emit_signal("damage_slime",Vector2(column + 1, row))				
	# Check left
	if(column>0):
		emit_signal("damage_slime",Vector2(column - 1, row))
	# Check down
	if(row<height - 1):
		emit_signal("damage_slime",Vector2(column, row + 1))
	# Check up
	if(row>0):
		emit_signal("damage_slime",Vector2(column, row-1))
	
func damage_special(column,row):
	emit_signal("damage_ice",Vector2(column,row))
	emit_signal("damage_lock",Vector2(column,row))
	check_concrete(column,row)
	check_slime(column,row)
	
func match_color(color):
	for i in width:
		for j in height:
			if(self.all_pieces[i][j] != null):
				if(self.all_pieces[i][j].color == color):
					if(self.all_pieces[i][j].is_column_bomb):
						self.match_all_in_column(i)
					if(self.all_pieces[i][j].is_row_bomb):
						self.match_all_in_row(j)
					if(self.all_pieces[i][j].is_adjacent_bomb):
						self.find_adjacent_pieces(i,j)
					self.match_and_dim(all_pieces[i][j])
					add_to_array(Vector2(i,j))
	get_tree().get_root().get_node("game_window/AudioStreamPlayer").stream = best_sfx			
	get_tree().get_root().get_node("game_window/AudioStreamPlayer").play()	

func clear_board():
	for i in width:
		for j in height:
			if(self.all_pieces[i][j] != null):
				self.match_and_dim(all_pieces[i][j])
				add_to_array(Vector2(i,j))
	
func _on_destroy_timer_timeout():
	self.destroy_matched()

func collapse_columns():
	for i in width:
		for j in height:
			if(self.is_piece_null(i,j) && !restricted_fill(Vector2(i,j))):
				for k in range(j + 1,height):
					if(self.all_pieces[i][k] != null):
						self.all_pieces[i][k].move(grid_to_pixel(i,j))	
						self.all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	self.destroy_sinkers()
	get_parent().get_node("refill_timer").start()		

func after_refill():
	for i in width:
		for j in height:
			if(!self.is_piece_null(i,j)):
				if(match_at(i,j,all_pieces[i][j].color) || self.all_pieces[i][j].matched):
					self.find_matches()
					get_parent().get_node("destroy_timer").start()		
					return
	self.streak = 1
	self.state = move
	self.move_checked = false
	if(!self.damaged_slime && !self.initial_fill):
		self.generate_slime()
	
	if(self.is_moves && !self.initial_fill):
		self.current_counter_value -= 1
		emit_signal("update_counter",self.current_counter_value)
		if(self.current_counter_value<=0):
			self.declare_game_over()

	self.damaged_slime = false
	self.initial_fill = false
	self.color_bomb_used = false
	
func find_normal_neighbor(column,row):
	# Check right
	if(self.is_in_grid(Vector2(column+1,row))):
		if(self.all_pieces[column+1][row] != null && !self.is_piece_sinker(column+1,row)):
			return Vector2(column + 1, row)	
	# Check left
	if(self.is_in_grid(Vector2(column-1,row))):
		if(self.all_pieces[column-1][row] != null && !self.is_piece_sinker(column-1,row)):
			return Vector2(column - 1, row)	
	# Check up
	if(self.is_in_grid(Vector2(column,row+1))):
		if(self.all_pieces[column][row+1] != null && !self.is_piece_sinker(column,row+1)):
			return Vector2(column, row + 1)	
	# Check down
	if(self.is_in_grid(Vector2(column,row-1))):
		if(self.all_pieces[column][row-1] != null && !self.is_piece_sinker(column,row-1)):
			return Vector2(column, row-1)	
	
	return null
	
func match_all_in_column(column):
		for i in height:
			if(self.all_pieces[column][i] != null && !self.is_piece_sinker(column,i)):
				if(self.all_pieces[column][i].is_row_bomb):
					self.match_all_in_row(i)
				if(self.all_pieces[column][i].is_adjacent_bomb):
					self.find_adjacent_pieces(column,i)
				if(self.all_pieces[column][i].is_color_bomb):
					self.match_color(self.all_pieces[column][i].color)
				self.all_pieces[column][i].matched = true
				
		get_tree().get_root().get_node("game_window/AudioStreamPlayer").stream = best_sfx			
		get_tree().get_root().get_node("game_window/AudioStreamPlayer").play()	
			
	
func match_all_in_row(row):
		for i in width:
			if(self.all_pieces[i][row] != null && !self.is_piece_sinker(i,row)):
				if(self.all_pieces[i][row].is_column_bomb):
					self.match_all_in_column(i)
				if(self.all_pieces[i][row].is_adjacent_bomb):
					self.find_adjacent_pieces(i,row)
				if(self.all_pieces[i][row].is_color_bomb):
					self.match_color(self.all_pieces[i][row].color)
				self.all_pieces[i][row].matched = true
		get_tree().get_root().get_node("game_window/AudioStreamPlayer").stream = best_sfx			
		get_tree().get_root().get_node("game_window/AudioStreamPlayer").play()	

func find_adjacent_pieces(column,row):
	for i in range(-1,2):
		for j in range(-1,2):
			if(self.is_in_grid(Vector2(column + i, row + j))):
				if(self.all_pieces[column + i][row + j] != null && !self.is_piece_sinker(column+i,row+j)):
					if(self.all_pieces[column  + i][row + j].is_column_bomb):
						self.match_all_in_column(column + i)
					if(self.all_pieces[column + i][row + j].is_row_bomb):
						self.match_all_in_row(row + j)
					if(self.all_pieces[column  + i][row + j].is_color_bomb):
						self.match_color(self.all_pieces[column  + i][row + j].color)
					self.all_pieces[column + i][row + j].matched = true
	get_tree().get_root().get_node("game_window/AudioStreamPlayer").stream = best_sfx			
	get_tree().get_root().get_node("game_window/AudioStreamPlayer").play()	
	
func destroy_sinkers():
	for i in width:
		if(self.all_pieces[i][0] != null):
			if(self.all_pieces[i][0].color == "None"):
				self.all_pieces[i][0].matched = true
				self.current_sinkers -= 1
	
					
func generate_slime():
	# Ensure there are slime pieces
	if(self.slime_spaces.size()>0):
		var slime_made = false
		var tracker = 0
		
		while(!slime_made && tracker<100):
			# Check random slime
			var random_num = floor(rand_range(0,slime_spaces.size()))
			var cur_x = self.slime_spaces[random_num].x
			var cur_y = self.slime_spaces[random_num].y
			var neighbor = find_normal_neighbor(cur_x,cur_y)
			if(neighbor != null):
				# Turn neighbor into slime
				self.all_pieces[neighbor.x][neighbor.y].queue_free()
				self.all_pieces[neighbor.x][neighbor.y] = null
				self.slime_spaces.append(Vector2(neighbor.x,neighbor.y))
				emit_signal("make_slime",Vector2(neighbor.x,neighbor.y))
				slime_made = true
			tracker += 1
			
			
			
func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	self.spawn_pieces()

func _on_lock_holder_remove_lock(place):
	for i in range(lock_spaces.size() - 1,-1,-1):
		if(lock_spaces[i] == place):
			lock_spaces.remove(i)

func _on_concrete_holder_remove_concrete(place):
	for i in range(concrete_spaces.size() - 1,-1,-1):
		if(concrete_spaces[i] == place):
			concrete_spaces.remove(i)


func _on_slime_holder_remove_slime(place):
	self.damaged_slime = true
	for i in range(slime_spaces.size() - 1,-1,-1):
		if(slime_spaces[i] == place):
			slime_spaces.remove(i)


func _on_Timer_timeout():
	self.current_counter_value -= 1
	emit_signal("update_counter",self.current_counter_value)
	if(self.current_counter_value <= 0):
		self.declare_game_over()
		$Timer.stop()
		
func declare_game_over():
	emit_signal("game_over")
	self.state = wait
	

func _on_GoalHolder_game_won():
	self.state = wait
