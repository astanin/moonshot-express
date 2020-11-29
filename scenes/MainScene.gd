extends Node2D


onready var Thing = preload('res://scenes/Thing.tscn')
onready var Things = get_node("Things")
onready var Rocket = get_node("Rocket")
onready var RocketInside = Rocket.get_node("Inside").get_node("Container")
onready var Wheel = get_node("Wheel")
onready var RocketAnimation = get_node("RocketAnimation")
onready var WheelAnimation = get_node("WheelAnimation")


onready var LastThing = null
var BeginRound = true
var FirstRound = true
var RocketStatus = "InSpace" # "InSpace", "", or "Landed"
var WheelVisible = false
export var CountdownTime = 60
export var StartingCash = 1_000_000_000.0
export var AvgLaunchCost = 800_000_000.0


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var tip_start = get_node("tip_start")
	tip_start.set_visible(true)
	Rocket.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_node("tip_move_and_place").hide()
	var balance = get_node("BalanceSheet")
	balance.reset(StartingCash)
	balance.visible = false


func cleanup_container(container):
	while container.get_child_count():
		var last = container.get_child(container.get_child_count() - 1)
		container.remove_child(last)
		last.queue_free()


func launch_rocket():
	RocketStatus = "IsLaunching"
	if WheelVisible:
		WheelAnimation.play("HideWheel")
	RocketAnimation.play("RocketLaunch")
	var fx = get_node("SoundFX/RocketLaunch")
	fx.play()
	cleanup_container(Things) # TODO add a nice animation
	get_node("tip_move_and_place").hide()
	var countdown = get_node("CountdownTimer")
	countdown.hide()
	get_node("Soundtrack/MainTheme").stop()


func land_rocket():
	RocketAnimation.play("RocketLanding")
	RocketStatus = "IsLanding"
	get_node("SoundFX/RocketLanding").play()
	BeginRound = true
	var balance = get_node("BalanceSheet")
	balance.visible = true
	if FirstRound:
		get_node("SoundFX/Profit").play()
		FirstRound = false


func _process(delta):
	if Input.is_action_just_pressed("start"):
		if RocketStatus == "InSpace":
			land_rocket()
	if Input.is_action_pressed("launch_rocket") and RocketStatus == "Landed":
		launch_rocket()
	if Input.is_key_pressed(KEY_M):
		var audio = get_node("Soundtrack/MainTheme")
		if audio.is_playing():
			if audio.get_playback_position() > 1:
				audio.stop()
		else:
			audio.play()


func _on_Wheel_item_selected(item):
	if RocketStatus != "Landed":
		return
	print("Selected: ", item.VisibleItem.name, "@", item.get_global_position())
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
	if RocketStatus != "Landed":
		return
	print("Placed: ", item.VisibleItem.name, "@", item.get_global_position())
	item.active = false
	reparent(item, RocketInside)
	# show cach-in animation
	var PaymentFX = get_node("PaymentFX")
	PaymentFX.get_node("Label").set_text(item.get_node("PriceLabel").get_text())
	PaymentFX.visible = true
	PaymentFX.set_global_position(item.get_global_position())
	PaymentFX.get_node("Label/AnimationPlayer").play("CashIn")
	# update balance
	var balance = get_node("BalanceSheet")
	var deliverycost = item.deliverycost
	balance.increase_revenue(deliverycost)
	# show wheel, hide tips
	if !WheelVisible:
		Wheel.visible = true
		WheelAnimation.play("ShowWheel", -1, 3.0)
	Wheel.active = true
	get_node("tip_move_and_place").hide()


func _on_CountdownTimer_count_zero():
	if RocketStatus == "Landed":
		launch_rocket()


# game states: # TODO rewrite as a formal FSM
# (Rocket in Space)
# [start] -> (Rocket landed, Wheel not available)
# [delay] -> (Rocket landed, Wheel available, show balance & countdown)
#     [count_zero] -> (Rocket launching, hide everything)
#                     [delay] -> (Rocket in Space, show results)
#     [select_item] -> (Placing item)
#                      [place_item] -> (Rocket landed, Wheel available)

func begin_round():
	BeginRound = false
	var timer = get_node("CountdownTimer")
	timer.visible = true
	timer.restart(CountdownTime, self)
	var balance = get_node("BalanceSheet")
	balance.visible = true
	var randomcost = round(
		rand_range(0.4*AvgLaunchCost, 0.6*AvgLaunchCost) +
		rand_range(0.4*AvgLaunchCost, 0.6*AvgLaunchCost)
		) # triangular distribution on (0.8, 1.0, 1.2)x of AvgLaunchCost
	balance.set_cost(-randomcost)
	get_node("SoundFX/Loss").play()
	get_node("Soundtrack/MainTheme/Transitions").play("FadeIn")
	get_node("Soundtrack/MainTheme").play()



func end_round():
	var timer = get_node("CountdownTimer")
	timer.visible = false
	var balance = get_node("BalanceSheet")
	#balance.visible = false
	var cost = balance.cost
	var revenue = balance.revenue
	var cash = balance.cash
	var profit = revenue + cost # cost is negative
	var newcash = cash + profit
	balance.reset(newcash)
	if profit > 0:
		get_node("SoundFX/Profit").play()
	else:
		get_node("SoundFX/Loss").play()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "RocketLanding":
		RocketStatus = "Landed"
		Wheel.visible = true
		if BeginRound:
			begin_round()
		WheelAnimation.play("ShowWheel")
		Wheel.hide_deliverycost()
		get_node("SoundFX/RocketLanding").stop()
	elif anim_name == "RocketLaunch":
		RocketStatus = "InSpace"
		cleanup_container(RocketInside)
		Wheel.refill()
		end_round()
	elif anim_name == "ShowWheel":
		WheelVisible = true
		Wheel.active = true
		Wheel.visible = true
		Wheel.show_deliverycost()
	elif anim_name == "HideWheel":
		WheelVisible = false
		Wheel.active = false
		Wheel.visible = false
