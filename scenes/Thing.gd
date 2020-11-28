extends KinematicBody2D

export var angular_speed = 180
export var speed = 200
export var active = false
export var deliverycost = 0
export var basecost = 200_000
export var basesize = 200*200.0


var direction = Vector2(1, 0)
var rocket = null


var Items = []
onready var VisibleItem = get_node("UnicornItem")


signal item_placed(item)


func calc_extent(Item):
	var p = Item.get_polygon()
	var s = Item.get_scale()
	var xmin = 9999
	var xmax = -9999
	var ymin = 9999
	var ymax = -9999
	for pt in p:
		var x = pt[0]*s[0]
		var y = pt[1]*s[1]
		xmin = min(xmin, x)
		xmax = max(xmax, x)
		ymin = min(ymin, y)
		ymax = max(ymax, y)
	return [xmax - xmin, ymax - ymin]


func calc_price_position(Item, y_to_x = 1):
	var p = Item.get_polygon()
	var s = Item.get_scale()
	var price_x = 0
	for pt in p:
		var x = pt[0]*s[0]
		var y = pt[1]*s[1]
		price_x = max(price_x, max(x, y / y_to_x))
	var price_y = y_to_x * price_x
	return Vector2(price_x, -price_y)


func choose_price(Item):
	# price proportional to its size and complexity
	var extent= calc_extent(VisibleItem)
	var size : float = extent[0]*extent[1]
	#var p : float = VisibleItem.get_polygon().size() / 6.0
	var targetprice = pow(size/basesize, 1.2) * basecost
	var randomprice = round(rand_range(0.9*targetprice, 1.1*targetprice))
	return randomprice

	
func update_show_price():
	# format deliverycost
	var n = deliverycost
	var n_s : String = "%.0f" % (n)
	if n >= 1e3:
		n_s = n_s.insert(n_s.length()-3, ",")
	if n >= 1e6:
		n_s = n_s.insert(n_s.length()-6-1, ",")
	if n >= 1e9:
		n_s = n_s.insert(n_s.length()-9-2, ",")
	var PriceLabel = get_node("PriceLabel")
	# show deliverycost
	PriceLabel.set_text("$" + n_s)
	PriceLabel.visible = true
	var name = VisibleItem.name
	var dp = PriceLabel.get_position()
	var pp = calc_price_position(VisibleItem, 0.5)
	var ip = VisibleItem.get_position()*VisibleItem.get_scale()
	var np = pp - ip
	PriceLabel.set_position(np)


func choose_item_type(idx):
	VisibleItem = Items[idx]
	#print("total items: ", Items.size(), ", random idx=", idx, ", selected=",VisibleItem.name)
	VisibleItem.disabled = false
	VisibleItem.visible = true
	deliverycost = choose_price(VisibleItem)
	update_show_price()
	


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
	choose_item_type(idx)


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


