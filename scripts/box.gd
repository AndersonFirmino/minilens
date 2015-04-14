extends KinematicBody2D
#This script is used for movable and static boxes
var ray_check_top # rays to check for objects in each direction
var ray_check_right
var ray_check_bottom
var ray_check_left

var collider_top = "" # Variables in which we store the colliders we find
var collider_right = ""
var collider_bottom = ""
var collider_left = ""

var check_top = "" # Variables in which we store the wiles in each direction
var check_right = ""
var check_bottom = ""
var check_left = ""

var sinking = false # Are we sinking?

var tilemap # the Tilemap
var movement = 0 # How much do we have to move? (+ for right)
var move_right = false # can we move left/right
var move_left = false
export var moveable = true # Can we move, or is this box a static one
export var TILE_ACID = 2 
export var TILE_LADDER = 1

func _ready():
	if(moveable):
		get_node("../../../level_holder").goal_add() # When we can move, we add a goal to the level
		set_fixed_process(true)
	# Getting nodes
	tilemap = get_node("../tilemap")
	ray_check_top = get_node("ray_check_top")
	ray_check_right = get_node("ray_check_right")
	ray_check_bottom = get_node("ray_check_bottom")
	ray_check_left = get_node("ray_check_left")
	

func destroy(var by): # Called whenever the box is destroyed
	if(moveable):
		if(by == "bomb"): # When we were demolished by a bomb
			get_node("../../../level_holder").goal_take(1)
		else:
			get_node("../../../level_holder").goal_take()
	queue_free() # delete the box from the scene

func _fixed_process(delta):
	if movement == 0: # We aren't moveing right now
		var current_position = get_pos()/64
		#fall
		var check_bottom = tilemap.get_cell(current_position.x, current_position.y + 1)
		var check_overlap = tilemap.get_cell(current_position.x, current_position.y)
		var check_top = tilemap.get_cell(current_position.x, current_position.y - 1)
		var move_down # can we move down
		if ray_check_bottom.is_colliding() and ray_check_bottom.get_collider():
			var collider_name = ray_check_bottom.get_collider().get_name()
			if(collider_name.substr(0,6) == "flower"): # When we fall into a flower
				move_down = true
				get_node("../../../level_holder").goal_take()
				ray_check_bottom.get_collider().queue_free()
			elif collider_name.substr(0,11) == "bomb_pickup": # When we fall into a bomb
				move_down = true
			else:
				move_down = false
		else:
			move_down = true
		if(check_top == TILE_ACID):#When we have fallen through the acid
			destroy("acid")
		
		#sinking
		if(check_bottom == TILE_ACID):
			if !sinking:
				sinking = true
				get_node("sink").play()
		
		if move_down && (check_bottom == -1 || check_bottom == TILE_LADDER) && check_overlap != TILE_ACID: # we are able to fall
			move(Vector2(0,4))
		else:
			#sink
			if(check_overlap == TILE_ACID || check_bottom == TILE_ACID):# if we can sink
				set_z(-1)
				move(Vector2(0,1))
			
			#check if we can move left
			if(tilemap.get_cell(current_position.x - 1, current_position.y) == 0):
				move_left = false
			elif ray_check_left.is_colliding() and ray_check_left.get_collider():
				check_left = ray_check_left.get_collider().get_name()
				if check_left.substr(0,3) == "box": # We can't move through boxes
					move_left = false
				else:
					move_left = true
			else:
				check_left == ""
				move_left = true
				
			#check if we can move right
			if(tilemap.get_cell(current_position.x + 1, current_position.y) == 0):
				move_right = false
			elif ray_check_right.is_colliding() and ray_check_right.get_collider():
				check_right = ray_check_right.get_collider().get_name()
				if check_right.substr(0,3) == "box": # We can't move through boxes
					move_right = false
				else:
					move_right = true
			else:
				check_right == ""
				move_right = true
			
			#Is the player pushing right?
			if ray_check_left.is_colliding() and move_right:
				collider_left = ray_check_left.get_collider()
				if collider_left and collider_left.get_name() == "player" && !collider_left.falling:
					if Input.is_action_pressed("btn_right") && collider_left.movement == 0:# the player doesn't move, and is pressing right, and doesn't fall
						movement = 64 # Both we and the player move 64 px left
						collider_left.movement = 64
						get_node("hit").play()
			else:
				collider_left = ""
				
			#Is the player pushing left?
			if ray_check_right.is_colliding() and move_left:
				collider_right = ray_check_right.get_collider()
				if collider_right and collider_right.get_name() == "player" && !collider_right.falling:
					if Input.is_action_pressed("btn_left") && collider_right.movement == 0:# the player doesn't move, and is pressing left, and doesn't fall
						movement = -64
						collider_right.movement = -64
						get_node("hit").play()
			else:
				collider_right = ""
				
	else:# When we are moving
		if movement > 0:
			movement -= 4
			move(Vector2(4,0))#Commit the move
		elif movement < 0:
			movement += 4
			move(Vector2(-4,0))#Commit the move

