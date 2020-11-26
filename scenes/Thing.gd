extends KinematicBody2D

export var angular_speed = 180
export var speed = 200
export var direction = Vector2(1, 0)
export var active = false
export var type = ""
var rocket = null

var Items = []

signal item_placed(item)


# Called when the node enters the scene tree for the first time.
func _ready():
	for ch in get_children():
		var ch_name = ch.name
		if ch_name.ends_with("Item"):
			ch.disabled = true
			ch.visible = false
			Items.push_back(ch)
	randomize()
	var idx = randi() % Items.size()
	var VisibleItem = Items[idx]
	#print("total items: ", Items.size(), ", random idx=", idx, ", selected=",VisibleItem.name)
	type = VisibleItem.name
	VisibleItem.disabled = false
	VisibleItem.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !active:
		return

	var rocket_Inside = rocket.get_node("Inside")
	var is_inside_rocket = rocket_Inside.overlaps_body(self)
	var rocket_Hatch = rocket.get_node("Hatch")
	var is_completely_inside = !rocket_Hatch.overlaps_body(self)
	if Input.is_action_pressed("place_item"):
		if is_inside_rocket and is_completely_inside:
			active = false
			self.set_owner(rocket)
			var fx = get_node("PlaceSound")
			fx.play()
			var MainScene = rocket.get_parent()
			connect("item_placed", MainScene, "_on_Thing_item_placed")
			emit_signal("item_placed", self)
		elif is_inside_rocket and !is_completely_inside:
			var fx = get_node("FailSound")
			fx.play()


	direction = Vector2(0, 0)
	if Input.is_action_pressed("move_right"):
		direction.x = Input.get_action_strength("move_right")
	elif Input.is_action_pressed("move_left"):
		direction.x = -Input.get_action_strength("move_left")
	if Input.is_action_pressed("move_up"):
		direction.y = -Input.get_action_strength("move_up")
	elif Input.is_action_pressed("move_down"):
		direction.y = Input.get_action_strength("move_down")
	move_and_collide(speed * direction * delta)

	set_position(get_position() + speed * direction * delta)
	var prev_rot = get_rotation_degrees()
	# TODO: detect rotation collisions and  avoid rotations
	var prev_t = get_transform()
	var phi = 0
	if Input.is_action_pressed('rotate_cw'):
		var s = Input.get_action_strength("rotate_cw")
		phi = s * angular_speed * delta * PI / 180
	if Input.is_action_pressed('rotate_ccw'):
		var s = Input.get_action_strength("rotate_ccw")
		phi = - s * angular_speed * delta * PI / 180
	var rotated_t = prev_t.rotated(phi)
	var would_collide = test_move(rotated_t, Vector2(0, 0))
	if !would_collide:
		set_rotation(rotated_t.get_rotation())


