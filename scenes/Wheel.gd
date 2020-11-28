extends Node2D


onready var Thing = preload('res://scenes/Thing.tscn')
onready var Items = get_node("AvailableItems")
onready var MainScene = get_parent()
onready var Rocket = MainScene.get_node("Rocket")


onready var Blip = get_node("SoundFX/Blip")


export var NumberOfSlots = 19
var Slots = []
var SelectedIndex = 0
var ItemRadius = 720
var AngularStep = PI * 2 / NumberOfSlots
var StepTime = 0.25
var active = false
var PrevAngle = 0
var NextAngle = 0
var RotationTime = -1


signal item_selected(item)


# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in range(NumberOfSlots):
		spawn_thing()
	SelectedIndex = NumberOfSlots - 4
	connect("item_selected", MainScene, "_on_Wheel_item_selected")


func is_rotating():
	return RotationTime >= 0 and RotationTime < StepTime


func refill():
	for i in range(NumberOfSlots):
		var SlotItem = Slots[i]
		if SlotItem == null:
			spawn_thing(i)
	

func deselect_item(index):
	if Slots.size() <= index or index < 0:
		pass
	var Item = Slots[index]
	if Item:
		Item.deselect_item()


func select_item(index):
	if Slots.size() <= index or index < 0:
		pass
	var Item = Slots[index]
	if Item:
		Item.select_item()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var rotating = is_rotating()
	if rotating:
		RotationTime += delta
		var t = min(RotationTime/StepTime, 1)
		Items.set_rotation(t*NextAngle + (1-t)*PrevAngle)
	else:
		select_item(SelectedIndex)
	
	if active and not rotating:
		if Input.is_action_pressed("wheel_next"):
			PrevAngle = Items.get_rotation()
			NextAngle = PrevAngle - AngularStep
			RotationTime = 0
			deselect_item(SelectedIndex)
			SelectedIndex = fmod(SelectedIndex + 1, NumberOfSlots)
			Blip.play()
		elif Input.is_action_pressed("wheel_prev"):
			PrevAngle = Items.get_rotation()
			NextAngle = PrevAngle + AngularStep
			RotationTime = 0
			deselect_item(SelectedIndex)
			SelectedIndex = fmod(SelectedIndex - 1, NumberOfSlots)
			Blip.play()
		elif Input.is_action_just_pressed("wheel_select"):
			var SelectedItem = Slots[SelectedIndex]
			if SelectedItem:
				Slots[SelectedIndex] = null
				var SceneThings = MainScene.get_node("Things")
				var gpos = SelectedItem.get_global_position()
				var grot = SelectedItem.get_global_rotation()
				SelectedItem.get_parent().remove_child(SelectedItem)
				SceneThings.add_child(SelectedItem)
				SelectedItem.set_global_position(gpos)
				SelectedItem.set_global_rotation(grot)
				emit_signal("item_selected", SelectedItem)
				active = false
				Blip.play()


func spawn_thing(index = -1):
	var idx
	if (index == -1):
		idx = Slots.size()
	else:
		idx = index 
	var newItem = Thing.instance()
	Items.add_child(newItem)
	var alpha = (idx + 2.25) * AngularStep
	var pos = Vector2(ItemRadius, 0).rotated(alpha) 
	newItem.set_position(pos)
	newItem.set_rotation(alpha)
	#newItem.set_rotation_degrees(randf()*360)
	newItem.rocket = Rocket
	newItem.active = false
	if Slots.size() <= idx:
		Slots.push_back(newItem)
	else:
		Slots[idx] = newItem
