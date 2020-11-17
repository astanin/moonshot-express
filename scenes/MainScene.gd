extends Node2D


onready var Thing = preload('res://scenes/Thing.tscn')
onready var Things = get_node("Things")
onready var Rocket = get_node("Rocket")
onready var AnimationPlayer = get_node("AnimationPlayer")
onready var LastThing = null
var RocketStatus = "InSpace" # "InSpace", "", or "Landed"

# Called when the node enters the scene tree for the first time.
func _ready():
	#spawn_thing()
	#AnimationPlayer.play("RocketLanding")
	#RocketStatus = ""
	pass


func _process(delta):
	if Input.is_key_pressed(KEY_SPACE):
		if RocketStatus == "Landed":
			AnimationPlayer.play("RocketLaunch")
			RocketStatus = ""
		elif RocketStatus == "InSpace":
			AnimationPlayer.play("RocketLanding")
			RocketStatus = ""
	spawn_thing()


func spawn_thing():
	if LastThing == null or not LastThing.active:
		var pt = Thing.instance()
		Things.add_child(pt)
		pt.set_position(Vector2(300, 200))
		pt.set_rotation_degrees(randf()*360)
		pt.rocket = Rocket
		pt.active = true
		LastThing = pt
	

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "RocketLanding":
		RocketStatus = "Landed"
	elif anim_name == "RocketLaunch":
		RocketStatus = "InSpace"
