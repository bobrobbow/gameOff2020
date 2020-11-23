extends RigidBody2D

export var jump_power = 1
export var movement_power = 10
const WALK_ACCEL = 800.0
const WALK_DEACCEL = 400.0
const WALK_MAX_VELOCITY = 200.0
const AIR_ACCEL = 200.0
const AIR_DEACCEL = 100.0
const JUMP_VELOCITY = 1000
const STOP_JUMP_FORCE = 450.0
const MAX_SHOOT_POSE_TIME = 0.3
const MAX_FLOOR_AIRBORNE_TIME = 20.0
var type = "Astronaut"
var siding_left = false
var jumping = false
var stopping_jump = false

var print_countdown = 60

var airborne_time = 1e20

var floor_h_velocity = 0.0

func _ready():
	pass
	
	
func _integrate_forces(s):
	get_parent().get_parent().get_node("Camera").position = position
	var lv = s.get_linear_velocity()
	var step = s.get_step()
	
	var new_siding_left = siding_left
	rotation_degrees = rad2deg(get_parent().get_node("top_of_moon").position.angle_to(position))
	# Get player input.
	var move_left = Input.is_action_pressed("character_left")
	var move_right = Input.is_action_pressed("character_right")
	var jump = Input.is_action_pressed("character_jump")
	
	
	# Deapply prev floor velocity.
	lv.x -= floor_h_velocity
	floor_h_velocity = 0.0
	
	# Find the floor (a contact with upwards facing collision normal).
	var found_floor = false
	var floor_index = -1
	
	for x in range(s.get_contact_count()):
		var ci = s.get_contact_local_normal(x)
		
		if ci.dot(Vector2(0, -1)) > 0.6:
			found_floor = true
			floor_index = x
	
	if found_floor:
		airborne_time = 0.0
	else:
		airborne_time += step # Time it spent in the air.
	
	var on_floor = airborne_time < MAX_FLOOR_AIRBORNE_TIME

	# Process jump.
	if jumping:
		if lv.y > 0:
			# Set off the jumping flag if going down.
			jumping = false
		elif not jump:
			stopping_jump = true
		
		if stopping_jump:
			lv.y += STOP_JUMP_FORCE * step
	
	if on_floor:
		# Process logic when character is on floor.
		if move_left and not move_right:
			$Sprite.scale.x = -5
			if lv.x > -WALK_MAX_VELOCITY:
				lv.x -= WALK_ACCEL * step
		elif move_right and not move_left:
			if lv.x < WALK_MAX_VELOCITY:
				lv.x += WALK_ACCEL * step
		else:
			$Sprite.scale.x = 5
			var xv = abs(lv.x)
			xv -= WALK_DEACCEL * step
			if xv < 0:
				xv = 0
			lv.x = sign(lv.x) * xv
		
		# Check jump.
		if not jumping and jump:
			lv.y = -JUMP_VELOCITY
			jumping = true
			stopping_jump = false
		
		# Check siding.
		if lv.x < 0 and move_left:
			new_siding_left = true
		elif lv.x > 0 and move_right:
			new_siding_left = false
		if jumping:
			pass
	else:
		# Process logic when the character is in the air.
		if move_left and not move_right:
			$Sprite.scale.x = -5
			if lv.x > -WALK_MAX_VELOCITY:
				lv.x -= AIR_ACCEL * step
		elif move_right and not move_left:
			$Sprite.scale.x = 5
			if lv.x < WALK_MAX_VELOCITY:
				lv.x += AIR_ACCEL * step
		else:
			var xv = abs(lv.x)
			xv -= AIR_DEACCEL * step
			
			if xv < 0:
				xv = 0
			lv.x = sign(lv.x) * xv
	# Update siding.
	if new_siding_left != siding_left:
		if new_siding_left:
			$Sprite.scale.x = -5
		else:
			$Sprite.scale.x = 5
		
		siding_left = new_siding_left
	
	# Apply floor velocity.
	if found_floor:
		pass
		#floor_h_velocity = s.get_contact_collider_velocity_at_position(floor_index).x
		#lv.x += floor_h_velocity
	# Finally, apply gravity and set back the linear velocity.
	if print_countdown < 0:
		print("rotation degrees = " + str(rotation_degrees))
		print(lv)
		print_countdown = 60
	else:
		print_countdown -= 1
	lv += s.get_total_gravity() * step
	s.set_linear_velocity(lv.rotated(deg2rad(rotation_degrees)))
