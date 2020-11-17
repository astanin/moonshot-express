extends KinematicBody2D

export var angular_speed = 180
export var speed = 200
export var direction = Vector2(1, 0)
export var active = false
var rocket = null

var Items = []

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
	print("total items: ", Items.size(), ", random idx=", idx, ", selected=",VisibleItem.name)
	VisibleItem.disabled = false
	VisibleItem.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !active:
		return

	var rocket_Inside = rocket.get_node("Inside")
	var is_inside_rocket = rocket_Inside.overlaps_body(self)
	if Input.is_action_pressed("place_item") and is_inside_rocket:
		active = false
		self.set_owner(rocket)
		var fx = get_node("PlaceSound")
		fx.play()

	direction = Vector2(0, 0)
	if Input.is_action_pressed("move_right"):
		direction = Vector2(1, 0)
	elif Input.is_action_pressed("move_left"):
		direction = Vector2(-1, 0)
	if Input.is_action_pressed("move_up"):
		direction.y = -1
	elif Input.is_action_pressed("move_down"):
		direction.y = 1
	move_and_collide(speed * direction * delta)

	set_position(get_position() + speed * direction * delta)
	if Input.is_action_pressed('rotate_cw'):
		set_rotation_degrees(get_rotation_degrees() - angular_speed * delta)
	if Input.is_action_pressed('rotate_ccw'):
		set_rotation_degrees(get_rotation_degrees() + angular_speed * delta)


