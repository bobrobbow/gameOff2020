extends Node

#export var structure_mgr: NodePath
export var min_damage_time_interval = 15
export var max_damage_time_interval = 180

#var _structure_mgr: StructureMgr

export var damage_active := true
export var debug := false

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalMgr.register_subscriber(self, "random_damage_test_clicked", "_on_random_damage_test_clicked")
	call_deferred("_init_damage_mgr")

func _init_damage_mgr():
	if StructureMgr.get_structure_mgr() == null:
		return
	if damage_active:
		_start_random_damage_timer()


func _on_random_damage_test_clicked():
	if StructureMgr.get_structure_mgr() == null:
		return
	damage_active = !damage_active
	if damage_active:
		_start_random_damage_timer()
	else:
		$DamageTimer.stop()

func _start_random_damage_timer():
	if !damage_active:
		return
	$DamageTimer.wait_time = rand_range(min_damage_time_interval,max_damage_time_interval)
	$DamageTimer.start()
	if debug:
		print("Damage timer set to wait for " + str($DamageTimer.wait_time) + " seconds")

func _on_DamageTimer_timeout():
	if !damage_active:
		$DamageTimer.stop()
		return
	var non_damaged_structures = StructureMgr.get_structure_mgr().get_damagable_structures()
	if non_damaged_structures == null || non_damaged_structures.size() < 1:
		print("No valid structures to damage")
		return
	var rand_structure: StructureMgr.StructureData = ArrayUtil.get_rand(non_damaged_structures)
	var structure_mgr := StructureMgr.get_structure_mgr()
	structure_mgr.damage_structure(rand_structure)
	# set random time for next damage
	_start_random_damage_timer()
