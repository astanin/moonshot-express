extends Node2D


onready var Thing = preload('res://scenes/Thing.tscn')
onready var Things = get_node("Things")
onready var Rocket = get_node("Rocket")
onready var RocketInside = Rocket.get_node("Inside").get_node("Container")
onready var Wheel = get_node("Wheel")
onready var RocketAnimation = get_node("RocketAnimation")
onready var WheelAnimation = get_node("WheelAnimation")
onready var LastThing = null
var RocketStatus = "InSpace" # "InSpace", "", or "Landed"
var WheelVisible = false


# Called when the node enters the scene tree for the first time.
func _ready():
	var tip_start = get_node("tip_start")
	tip_start.set_visible(true)


func cleanup_container(container):
	while container.get_child_count():
		var last = container.get_child(container.get_child_count() - 1)
		container.remove_child(last)
		last.queue_free()


func _process(delta):
	if Input.is_action_pressed("start"):
		print("rocket:",RocketStatus,", wheel:",WheelVisible)
		if RocketStatus == "Landed":
			if WheelVisible:
				WheelAnimation.play("HideWheel")
			RocketAnimation.play("RocketLaunch")
			RocketStatus = "IsLaunching"
			cleanup_container(Things) # TODO add a nice animation
		elif RocketStatus == "InSpace":
			RocketAnimation.play("RocketLanding")
			RocketStatus = "IsLanding"


func _on_Wheel_item_selected(item):
	print("Selected: ", item.type, "@", item.get_global_position())
	Wheel.active = false
	if WheelVisible:
		WheelAnimation.play("HideWheel", -1, 3.0)
	item.active = true


func reparent(item, newcontainer):
	var gpos = item.get_global_position()
	var grot = item.get_global_rotation()
	item.get_parent().remove_child(item)
	newcontainer.add_child(item)
	item.set_global_position(gpos)
	item.set_global_rotation(grot)
	

func _on_Thing_item_placed(item):
	print("Placed: ", item.type, "@", item.get_global_position())
	item.active = false
	reparent(item, RocketInside)
	if !WheelVisible:
		WheelAnimation.play("ShowWheel", -1, 3.0)
	Wheel.active = true


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "RocketLanding":
		RocketStatus = "Landed"
		WheelAnimation.play("ShowWheel")
	elif anim_name == "RocketLaunch":
		RocketStatus = "InSpace"
		cleanup_container(RocketInside)
		Wheel.refill()
	elif anim_name == "ShowWheel":
		WheelVisible = true
		Wheel.active = true
	elif anim_name == "HideWheel":
		WheelVisible = false
		Wheel.active = false
