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
export var CountdownTime = 60


# Called when the node enters the scene tree for the first time.
func _ready():
	var tip_start = get_node("tip_start")
	tip_start.set_visible(true)
	Rocket.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_node("tip_move_and_place").hide()
	get_node("AudioStreamPlayer").play()


func cleanup_container(container):
	while container.get_child_count():
		var last = container.get_child(container.get_child_count() - 1)
		container.remove_child(last)
		last.queue_free()


func launch_rocket():
	if WheelVisible:
		WheelAnimation.play("HideWheel")
	RocketAnimation.play("RocketLaunch")
	RocketStatus = "IsLaunching"
	var fx = get_node("SoundFX/RocketLaunch")
	fx.play()
	cleanup_container(Things) # TODO add a nice animation
	get_node("tip_move_and_place").hide()


func land_rocket():
	RocketAnimation.play("RocketLanding")
	RocketStatus = "IsLanding"
	get_node("SoundFX/RocketLanding").play(48)


func _process(delta):
	if Input.is_action_just_pressed("start"):
		if RocketStatus == "InSpace":
			land_rocket()
	# DEBUG ONLY:
	if Input.is_key_pressed(KEY_SPACE): # TODO replace with timer
		if RocketStatus == "Landed":
			launch_rocket()
		elif RocketStatus == "InSpace":
			land_rocket()


func _on_Wheel_item_selected(item):
	#print("Selected: ", item.VisibleItem.name, "@", item.get_global_position())
	Wheel.active = false
	if WheelVisible:
		WheelAnimation.play("HideWheel", -1, 3.0)
		get_node("tip_move_and_place").show()
	item.get_node("PriceLabel").visible = false
	item.active = true


func reparent(item, newcontainer):
	var gpos = item.get_global_position()
	var grot = item.get_global_rotation()
	item.get_parent().remove_child(item)
	newcontainer.add_child(item)
	item.set_global_position(gpos)
	item.set_global_rotation(grot)
	

func _on_Thing_item_placed(item):
	print("Placed: ", item.VisibleItem.name, "@", item.get_global_position())
	item.active = false
	reparent(item, RocketInside)
	if !WheelVisible:
		Wheel.visible = true
		WheelAnimation.play("ShowWheel", -1, 3.0)
	Wheel.active = true
	get_node("tip_move_and_place").hide()


func _on_CountdownTimer_count_zero():
	if RocketStatus == "Landed":
		launch_rocket()
	

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "RocketLanding":
		RocketStatus = "Landed"
		var timer = get_node("CountdownTimer")
		timer.restart(CountdownTime, self)
		Wheel.visible = true
		WheelAnimation.play("ShowWheel")
		get_node("SoundFX/RocketLanding").stop()
	elif anim_name == "RocketLaunch":
		RocketStatus = "InSpace"
		cleanup_container(RocketInside)
		Wheel.refill()
	elif anim_name == "ShowWheel":
		WheelVisible = true
		Wheel.active = true
		Wheel.visible = true
	elif anim_name == "HideWheel":
		WheelVisible = false
		Wheel.active = false
		Wheel.visible = false
