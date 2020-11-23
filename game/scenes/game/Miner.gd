extends KinematicBody2D

var move_speed = 1000
var target = null
var move_left = false
var move_right = false
var spawn_mgr
var default_modulate = null
var stopped = false

func _ready():
	spawn_mgr = Globals.get("SpawnMgr")

func _process(delta):
	if default_modulate == null:
		for x in spawn_mgr.fragments:
			if x != target:
				default_modulate = x.get_node("Sprite").get_modulate()
	var temp_target = spawn_mgr._get_closest_landed_fragment(self.global_position)
	if temp_target != null:
		if temp_target != target and target != null:
			target.get_node("Sprite").set_modulate(default_modulate)
		target = temp_target
		target.get_node("Sprite").set_modulate(Color(0, 255, 0, 255))
		var norm_dir = global_position.direction_to(target.global_position).normalized()
		var up_dir = global_position.direction_to($up.global_position).normalized()
		var angle_diff = rad2deg(up_dir.angle_to(norm_dir))
		if angle_diff > 0 and angle_diff < 180:
			move_left = false
			move_right = true
		else:
			move_left = true
			move_right = false

func _stop_movement():
	stopped = true
	move_left = false
	move_right = false

func _physics_process(delta):
	var direction = Vector2(0,0)
	var bodies = get_node("Area2D").get_overlapping_bodies()
	for x in bodies:
		if "type" in x and x.type == "Fragment" and x == target:
			_collide_with_target(x)
	rotation_degrees = rad2deg(position.angle_to_point(Vector2(0,0)) ) + 90
	if !stopped and target != null:
		if move_left:
			$Sprite.flip_h = true
			direction = global_position.direction_to($left.global_position)
		elif move_right:
			$Sprite.flip_h = false
			direction = global_position.direction_to($right.global_position)
	_solve_movement(direction)

func _solve_movement(direction):
	var zeroed = direction == Vector2(0,0)
	var downwards = global_position.direction_to($down.global_position)
	direction = direction * move_speed
	direction += downwards * 100
	if zeroed:
		move_and_collide(direction)
	else:
		move_and_slide(direction)

func _collide_with_target(body):
	spawn_mgr._remove_fragment(body)

func _on_Area2D_body_entered(body):
	if "type" in body and body.type == "Fragment":
		if body == target:
			_collide_with_target(body)

