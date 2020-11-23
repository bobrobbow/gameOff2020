extends Node
var checked = false
onready var asteroid_scene = preload("res://scenes/game/Asteroid.tscn")
var asteroids = []
var fragments = []
var asteroid_sprites = []
var fragment_sprites = []
var spawn_extents_min = Vector2(-13233,-9203.9)
var spawn_extents_max = Vector2(13233,9203.9)
var miner_node = null
signal minerspawned(miner_node)

onready var fragment_scene = preload("res://scenes/game/Fragment.tscn")
onready var miner_scene = preload("res://scenes/game/Miner.tscn")
export var min_time_between_asteroids:float = 1 #seconds
export var max_time_between_asteroids:float = 2
export var debug := false

var shower_active = false

var miner_deployed = false

# how many asteroids can exist in scene at once
export var max_concurrent_asteroids = 20

# how many segments are launched after collision
export var min_asteroid_segments: int = 4
export var max_asteroid_segments: int = 8
export var fragment_limit = 200
# how much variance in the change in velocity by which they are ejected
export var fragment_propel_variance_min = 0.6
export var fragment_propel_variance_max = 1.0


onready var spawn_limit_rect := $ReferenceRect

func _ready():
	Globals.set("SpawnMgr", self)
	SignalMgr.register_publisher(self, "minerspawned")
	SignalMgr.register_subscriber(self, "AsteroidShowerEvent", "_on_AsteroidShowerEvent")
	spawn_extents_min.x = spawn_limit_rect.rect_global_position.x
	spawn_extents_min.y = spawn_limit_rect.rect_global_position.y
	spawn_extents_max.x = abs(spawn_limit_rect.rect_global_position.x)
	spawn_extents_max.y = abs(spawn_limit_rect.rect_global_position.y)
	_load_sprites("res://assets/images/asteroids", asteroid_sprites)
	_load_sprites("res://assets/images/asteroids/fragments", fragment_sprites )
	if asteroid_sprites.empty():
		print("errror loading asteroid sprites")

func _deploy_miner():
	var miner = miner_scene.instance()
	miner.position = Vector2(0,-3580)
	miner_node = miner
	emit_signal("minerspawned")
	get_parent().add_child(miner)

func _on_AsteroidShowerEvent(event_dict):
	var new_time = event_dict["duration"]
	if shower_active:
		# new shower started during a current one
		# just add the duration on
		$ShowerDurationTimer.wait_time += new_time
	print("asteroid shower event signalled")
	shower_active = true
	$ShowerDurationTimer.wait_time = new_time
	$ShowerDurationTimer.start()
	_start_spawn_timer()

func _process(delta):
	if fragments.size() > fragment_limit:
		var to_remove = fragments[0]
		fragments.erase(to_remove)
		to_remove.queue_free()
	for i in asteroids:
		if _is_out_of_bounds(i):
			i.queue_free()
			asteroids.erase(i)
			if debug:
				print("asteroid out of bounds, despawning")
	for i in fragments:
		if !is_instance_valid(i):
			fragments.erase(i)
		if _is_out_of_bounds(i):
			i.queue_free()
			fragments.erase(i)
			
func _check_fragment_list():
	while fragments.size() > fragment_limit:
		_remove_fragment(fragments[0])
	for i in range(fragments.size() -1, -1, -1):
		if _is_out_of_bounds(fragments[i]):
			_remove_fragment(fragments[i])

func _remove_fragment(fragment):
	if fragments.has(fragment):
		fragments.erase(fragment)
		fragment.queue_free()

func _is_landed(fragment) -> bool:
	if _is_fragment_stationary(fragment):
		var resting_bodies = fragment.get_colliding_bodies()
		for i in resting_bodies:
			if i.get_class() == "StaticBody2D" and i.get_name() == "MoonSurfaceBody":
				return true
	return false

func _get_closest_landed_fragment(from_pos : Vector2):
	_check_fragment_list() # ensure fragment list is correct first
	var closest = null
	for i in fragments:
		if _is_landed(i):
			if closest == null:
				closest = i
			else:
				if from_pos.distance_to(i.global_position) < \
					from_pos.distance_to(closest.global_position):
					closest = i
	return closest

func _is_fragment_stationary(i):
	return i.linear_velocity.x < 25 and i.linear_velocity.x > -25\
			and i.linear_velocity.y < 25 and i.linear_velocity.y > -25

func _is_out_of_bounds(body):
	if body.global_position.x > spawn_extents_max.x + 5000 or \
		body.global_position.x < spawn_extents_min.x - 5000 or \
		body.global_position.y > spawn_extents_max.y + 5000 or \
		body.global_position.y < spawn_extents_min.y - 5000:
			return true
	return false


func _input(event):
	if !miner_deployed and event.is_action_pressed("spawnminer") and not event.is_echo():
		_deploy_miner()
		miner_deployed = true
	if event.is_action_pressed("ui_focus_next") and not event.is_echo():
		var new_event = {}
		new_event["time"] = 0#dosnt matter
		new_event["type"] = 0
		new_event["duration"] = 8
		_on_AsteroidShowerEvent(new_event)


func _spawn_asteroid():
	if shower_active:
		if asteroids.size() >= max_concurrent_asteroids:
			_start_spawn_timer()
			return
		else:
			var asteroid = asteroid_scene.instance()
			asteroid.get_node("Sprite").texture = ArrayUtil.get_rand(asteroid_sprites)
			var spawn_pos = Vector2(7500,0)
			if randi() % 2 == 0:
				#spawn along top or bottom
				if randi() % 2 == 0:
					#spawn top
					spawn_pos.y = spawn_extents_min.y + 100
				else:
					#spawn bottom
					spawn_pos.y = spawn_extents_max.y - 100
				spawn_pos.x = rand_range((spawn_extents_max.x / 2 ) + 100, spawn_extents_max.x - 100)
			else:
				#spawn right side
				spawn_pos.x = (spawn_extents_max.x ) - 100
				spawn_pos.y = rand_range(spawn_extents_min.y + 100, spawn_extents_max.y - 100)
			var initial_kick = spawn_pos.direction_to(Vector2(0,0)).rotated(rand_range(-45,45))
			initial_kick = initial_kick * rand_range( 1000, 7500)
			asteroid.position = spawn_pos
			asteroids.append(asteroid)
			# delay kick to let physics body settle after spawning
			asteroid.delayed_kick_impulse = initial_kick
			asteroid.delayed_torque_impulse = rand_range(-1000,1000)
			add_child(asteroid)
			if debug:
				print("added asteroid at " + str(spawn_pos))

func _start_spawn_timer():
	$AsteroidTimer.wait_time = rand_range(min_time_between_asteroids,max_time_between_asteroids)
	$AsteroidTimer.start()

func _load_sprites(path, array):
	var direc = Directory.new()
	direc.open(path)
	direc.list_dir_begin()
	while true:
		var FileName = direc.get_next()
		if FileName == "":
			break
		elif !FileName.begins_with(".") and !FileName.ends_with(".import") and !direc.dir_exists(path + "/" + FileName):
			array.append(load(path + "/" + FileName))
	direc.list_dir_end()
	
func _on_AsteroidTimer_timeout():
	if !shower_active:
		$AsteroidTimer.stop()
		return
	_spawn_asteroid()
	_start_spawn_timer()

func _asteroid_impact(body : RigidBody2D ):
	body._mark_for_disintegration()

func _disintegrate(body):
	# create a random number of debris parts
	# some will eject off into space
	# some will form an orbit "ring" around the moon
	# some will settle on the surface.
	# TODO: base number of fragments on random asteroid size?
	var segments = int(rand_range(min_asteroid_segments,max_asteroid_segments))
	for i in range(0,segments):
		var new_fragment = fragment_scene.instance()
		#kick it
		new_fragment.position = body.position
		new_fragment.linear_velocity = \
			body.linear_velocity.rotated(rand_range(-45,45))
		new_fragment.linear_velocity = new_fragment.linear_velocity * \
			rand_range(fragment_propel_variance_min, fragment_propel_variance_max)
		new_fragment.angular_velocity = body.angular_velocity \
			+ rand_range(-20,20)
		fragments.append(new_fragment)
		call_deferred("add_child",new_fragment)
	asteroids.erase(body)
	body.queue_free()

func _on_ShowerDurationTimer_timeout():
	shower_active = false
	$AsteroidTimer.stop()
