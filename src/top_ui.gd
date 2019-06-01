extends Sprite

onready var score_label = $MarginContainer/HBoxContainer/VBoxContainer/ScoreLabel
onready var counter_label = $MarginContainer/HBoxContainer/CounterLabel
onready var score_bar = $MarginContainer/HBoxContainer/VBoxContainer/TextureProgress
onready var goal_container = $MarginContainer/HBoxContainer/HBoxContainer
export (PackedScene) var goal_prefab

var current_score = 0
var current_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	self._on_grid_update_score(current_score)

func _on_grid_update_score(amount_to_change):
	current_score += amount_to_change
	self.update_score_bar()
	score_label.text = String(current_score)	


func _on_grid_update_counter(new_count_value):
	current_count = new_count_value
	counter_label.text = String(current_count)

func setup_score_bar(max_score):
	score_bar.max_value = max_score
	
func update_score_bar():
	score_bar.value = current_score
	
func make_goal(new_max,new_texture,new_value):
	var current = goal_prefab.instance()
	goal_container.add_child(current)
	current.set_goal_values(new_max,new_texture,new_value)


func _on_grid_setup_max_score(max_score):
	self.setup_score_bar(max_score)


func _on_GoalHolder_create_goal(new_max,new_texture,new_value):
	self.make_goal(new_max,new_texture,new_value)


func _on_grid_check_goal(goal_type):
	for i in goal_container.get_child_count():
		goal_container.get_child(i).update_goal_values(goal_type)

func _on_ice_holder_break_ice(goal_type):
	for i in goal_container.get_child_count():
		goal_container.get_child(i).update_goal_values(goal_type)
