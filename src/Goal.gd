extends Node

# Goal info
export (Texture) var goal_texture
export (int) var max_needed
export (String) var goal_string
var num_collected = 0
var goal_met = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func check_goal(goal_type):
	if(goal_type == goal_string):
		self.update_goal()
	
func update_goal():
	if(self.num_collected < self.max_needed):
		self.num_collected += 1
	if(self.num_collected >= self.max_needed):
		if(!goal_met):
			goal_met = true

