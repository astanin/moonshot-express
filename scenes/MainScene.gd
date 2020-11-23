extends Node2D


onready var Thing = preload('res://scenes/Thing.tscn')
onready var Things = get_node("Things")
onready var Rocket = get_node("Rocket")
onready var Wheel = get_node("Wheel")
onready var AnimationPlayer = get_node("AnimationPlayer")
onready var LastThing = null
var RocketStatus = "InSpace" # "InSpace", "", or "Landed"
var WheelVisible = false


# Called when the node enters the scene tree for the first time.
func _ready():
	#spawn_thing()
	#AnimationPlayer.play("RocketLanding")
	#RocketStatus = ""
	var tip_start = get_node("tip_start")
	tip_start.set_visible(true)


func _process(delta):
	if Input.is_action_pressed("start"):
		print(RocketStatus, WheelVisible)
		if RocketStatus == "Landed":
			if WheelVisible:
				AnimationPlayer.animation_set_next("HideWheel", "RocketLaunch")
				AnimationPlayer.play("HideWheel")
			else:
				AnimationPlayer.play("RocketLaunch")
			RocketStatus = "IsLaunching"
		elif RocketStatus == "InSpace":
			AnimationPlayer.play("RocketLanding")
			RocketStatus = "IsLanding"

	#if RocketStatus == "Landed":
	#	spawn_thing()


#func spawn_thing():
#	if LastThing == null or not LastThing.active:
#		var pt = Thing.instance()
#		Things.add_child(pt)
#		pt.set_position(Vector2(300, 200))
#		pt.set_rotation_degrees(randf()*360)
#		pt.rocket = Rocket
#		pt.active = true
#		LastThing = pt

	

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "RocketLanding":
		RocketStatus = "Landed"
		AnimationPlayer.play("ShowWheel")
	elif anim_name == "RocketLaunch":
		RocketStatus = "InSpace"
	elif anim_name == "ShowWheel":
		WheelVisible = true
	elif anim_name == "HideWheel":
		WheelVisible = false
