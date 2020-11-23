extends Node2D


onready var Thing = preload('res://scenes/Thing.tscn')
onready var Items = get_node("AvailableItems")
onready var Rocket = get_parent()


export var NumberOfSlots = 19
var Slots = []
var ItemRadius = 720
var AngularStep = PI * 2 / NumberOfSlots
var StepTime = 1.0
var active = true
var PrevAngle = 0
var NextAngle = 0
var RotationTime = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(NumberOfSlots):
		spawn_thing()


func is_rotating():
	return RotationTime >= 0 and RotationTime < StepTime


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var rotating = is_rotating()
	if rotating:
		RotationTime += delta
		var t = min(RotationTime/StepTime, 1)
		Items.set_rotation(t*NextAngle + (1-t)*PrevAngle)
	
	if active and not rotating:
		if Input.is_action_just_pressed("wheel_next"):
			PrevAngle = Items.get_rotation()
			NextAngle = PrevAngle - AngularStep
			RotationTime = 0
		elif Input.is_action_just_pressed("wheel_prev"):
			PrevAngle = Items.get_rotation()
			NextAngle = PrevAngle + AngularStep
			RotationTime = 0


func spawn_thing():
	var idx = Slots.size()
	var newItem = Thing.instance()
	Items.add_child(newItem)
	var alpha = (idx + 2.25) * AngularStep
	var pos = Vector2(ItemRadius, 0).rotated(alpha) 
	newItem.set_position(pos)
	newItem.set_rotation(alpha)
	#newItem.set_rotation_degrees(randf()*360)
	newItem.rocket = Rocket
	newItem.active = false
	Slots.push_back(newItem)
