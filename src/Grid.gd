extends Node2D

export (int) var width;
export (int) var height;
export (int) var x_start;
export (int) var y_start;
export (int) var offset;

var all_pieces = [];

var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)
var controlling = false
var y_offset = 2

enum {wait, move}
var state

var possible_pieces = [
	preload("res://Scenes/yellow_piece.tscn"),
	preload("res://Scenes/blue_piece.tscn"),
	preload("res://Scenes/pink_piece.tscn"),
	preload("res://Scenes/orange_piece.tscn"),
	preload("res://Scenes/green_piece.tscn"),
	preload("res://Scenes/light_green_piece.tscn")
];

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	self.all_pieces = self.make_2d_array();
	self.spawn_pieces()
	self.state = move

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
	
func touch_input():
	if(Input.is_action_just_pressed("ui_touch")):
		if(self.is_in_grid(self.pixel_to_grid(get_global_mouse_position()))):
			first_touch = self.pixel_to_grid(get_global_mouse_position())
			controlling = true
	if(Input.is_action_just_released("ui_touch")):
		if(controlling && self.is_in_grid(self.pixel_to_grid(get_global_mouse_position()))):
			controlling = false
			final_touch = self.pixel_to_grid(get_global_mouse_position())
			self.touch_difference(first_touch,final_touch)
			
func swap_pieces(column,row,direction):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if(first_piece!=null && other_piece!=null):
		self.state = wait
		all_pieces[column][row] = other_piece
		all_pieces[column + direction.x][row + direction.y] = first_piece
		first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
		other_piece.move(grid_to_pixel(column,row))
		self.find_matches()
	
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
func spawn_pieces():
	for i in width:
		for j in height:
			if(self.all_pieces[i][j] == null):
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
		
func match_at(i, j, color):
	if(i>1):
		if(self.all_pieces[i-1][j] != null && self.all_pieces[i-2][j] != null):
			if(self.all_pieces[i-1][j].color == color && self.all_pieces[i-2][j].color == color):
				return true
	if(j>1):		
		if(self.all_pieces[i][j-1] != null && self.all_pieces[i][j-2] != null):
			if(self.all_pieces[i][j-1].color == color && self.all_pieces[i][j-2].color == color):
				return true
			

func grid_to_pixel(column, row):
	var new_x = x_start + offset * column;
	var new_y = y_start - offset * row;
	return Vector2(new_x,new_y);


func pixel_to_grid(cur_pos):
	var new_x = round((cur_pos.x - x_start) / offset);
	var new_y = round((cur_pos.y - y_start) /-offset);
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
			if(self.all_pieces[i][j] != null):
				var current_color = self.all_pieces[i][j].color
				if(i>0 && i<width -1):
					if(self.all_pieces[i-1][j] != null && self.all_pieces[i+1][j] != null):
						if(self.all_pieces[i-1][j].color == current_color && self.all_pieces[i+1][j].color == current_color):
							match_found = true
							self.all_pieces[i+1][j].matched = true
							self.all_pieces[i+1][j].dim()
							self.all_pieces[i-1][j].matched = true
							self.all_pieces[i-1][j].dim()
							self.all_pieces[i][j].matched = true
							self.all_pieces[i][j].dim()
				if(j>0 && j<height -1):
					if(self.all_pieces[i][j-1] != null && self.all_pieces[i][j+1] != null):
						if(self.all_pieces[i][j-1].color == current_color && self.all_pieces[i][j+1].color == current_color):
							match_found = true
							self.all_pieces[i][j+1].matched = true
							self.all_pieces[i][j+1].dim()
							self.all_pieces[i][j-1].matched = true
							self.all_pieces[i][j-1].dim()
							self.all_pieces[i][j].matched = true
							self.all_pieces[i][j].dim()
	if(match_found):
		get_parent().get_node("destroy_timer").start()

func destroy_matched():
	for i in width:
		for j in height:
			if(all_pieces[i][j] != null):
				if(all_pieces[i][j].matched):
					self.all_pieces[i][j].queue_free()
					self.all_pieces[i][j] = null
	get_parent().get_node("collapse_timer").start()
								
func _on_destroy_timer_timeout():
	self.destroy_matched()

func collapse_columns():
	for i in width:
		for j in height:
			if(self.all_pieces[i][j] == null):
				for k in range(j + 1,height):
					if(self.all_pieces[i][k] != null):
						self.all_pieces[i][k].move(grid_to_pixel(i,j))	
						self.all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()		

func after_refill():
	for i in width:
		for j in height:
			if(all_pieces[i][j] != null):
				if(match_at(i,j,all_pieces[i][j].color)):
					self.find_matches()
					get_parent().get_node("destroy_timer").start()		
					return
	self.state = move
					
func _on_collapse_timer_timeout():
	collapse_columns()


func _on_refill_timer_timeout():
	self.spawn_pieces()
