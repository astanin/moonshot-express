extends Node2D


onready var PinkThing = preload('res://scenes/PinkThing.tscn')
onready var Things = get_node("Things")
onready var Rocket = get_node("Rocket")
onready var LastThing = null

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_thing()


func _process(delta):
	spawn_thing()

func spawn_thing():
	if LastThing == null or not LastThing.active:
		var pt = PinkThing.instance()
		Things.add_child(pt)
		pt.set_position(Vector2(300, 200))
		pt.set_rotation_degrees(randf()*360)
		pt.rocket = Rocket
		pt.active = true
		LastThing = pt
	