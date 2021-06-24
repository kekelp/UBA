extends RigidBody2D

#var force: Vector2
var should_reset = false
var reset_pos = Vector2(0,0)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

#func _process(_delta):
#	$g.rotation = -self.rotation
#	$name.position = self.gl

func _integrate_forces(state):
	if should_reset == true:
		print("teleporting pos", should_reset)
		state.transform.origin = reset_pos
		should_reset = false
		get_parent().respawning = false

		print("end of respawn, changing spect mode to false")
		print("position ", get_parent().global_position)
		print("elim lives ", get_parent().elim_lives)
		get_parent().spectator_mode = false

