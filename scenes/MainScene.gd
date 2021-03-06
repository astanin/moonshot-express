extends Node2D


onready var Thing = preload('res://scenes/Thing.tscn')
onready var Things = get_node("Things")
onready var Rocket = get_node("Rocket")
onready var RocketInside = Rocket.get_node("Inside").get_node("Container")
onready var Wheel = get_node("Wheel")
onready var RocketAnimation = get_node("RocketAnimation")
onready var WheelAnimation = get_node("WheelAnimation")
onready var GameMenu = get_node("GameMenu")
onready var CreditsPage = get_node("CreditsPage")


onready var LastThing = null
var FirstRound = true
var RocketStatus = "InSpace" # "InSpace", "", or "Landed"
var RoundState = "BeginRound" # "Loading", "RoundSummary"
var WheelVisible = false
export var CountdownTime = 60
export var StartingCash = 1_000_000_000.0
export var AvgLaunchCost = 800_000_000.0
export var DiscountCoef = 1.0 # 1.0 = no discount = easy


func reset_balance():
	var balance = get_node("BalanceSheet")
	balance.reset(StartingCash)
	balance.visible = false


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var tip_start = get_node("tip_start")
	tip_start.set_visible(true)
	Rocket.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_node("tip_move_and_place").hide()
	get_node("RoundSummary").visible = false
	reset_balance()


func cleanup_container(container):
	while container.get_child_count():
		var last = container.get_child(container.get_child_count() - 1)
		container.remove_child(last)
		last.queue_free()


func launch_rocket():
	RocketStatus = "IsLaunching"
	if WheelVisible:
		WheelAnimation.play("HideWheel")
	else: # Wheel animation is still playing probably
		WheelAnimation.stop()
		Wheel.visible = false
		Wheel.active = false
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
	get_node("RoundSummary").visible = false
	RoundState = "BeginRound"
	var balance = get_node("BalanceSheet")
	balance.visible = true
	if FirstRound:
		get_node("SoundFX/Profit").play()
		FirstRound = false

	

func _process(delta):
	var RoundSummary = get_node("RoundSummary")
	if Input.is_action_just_pressed("start") and RoundSummary.visible:
		if get_node("BalanceSheet").cash <= 0:
			reset_balance()
		RoundSummary.visible = false
		land_rocket()
	elif Input.is_action_just_pressed("start") and RocketStatus == "InSpace":
		land_rocket()
	elif Input.is_action_pressed("launch_rocket") and RocketStatus == "Landed" and !Wheel.visible:
		launch_rocket()
	elif Input.is_action_just_released("game_menu"):
		if GameMenu:
			GameMenu.show()
			get_tree().paused = true
	elif Input.is_action_just_released("mute_sound"):
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
	RoundState = "Loading"
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
	get_node("Soundtrack/MainTheme").play()


# duplicate code, copied from BalanceSheet
# TODO: move to a separate script
func format_money(n):
	var is_negative = n < 0
	var n_s = "%.0f" % abs(n)
	var ts_pos = 3
	var ts_pow = 3
	while abs(n) >= pow(10, ts_pow):
		n_s = n_s.insert(n_s.length() - ts_pos, ",")
		ts_pos += 4
		ts_pow += 3
	if is_negative:
		n_s = " -$" + n_s
	else:
		n_s = "+$" + n_s
	return n_s


func show_summary(profit, cash):
	get_node("RoundSummary").visible = true
	if cash <= 0:
		var s = format_money(profit)
		get_node("RoundSummary/GameOver/Losses").set_text(s)
		get_node("RoundSummary/AnimationPlayer").play("GameOver")
		get_node("SoundFX/GameOver").play()
	elif profit > 0:
		var s = format_money(profit)
		get_node("RoundSummary/Profit/Profits").set_text(s)
		get_node("RoundSummary/AnimationPlayer").play("Profit")
		get_node("SoundFX/Profit").play()
	else:
		var s = format_money(profit)
		get_node("RoundSummary/Loss/Losses").set_text(s)
		get_node("RoundSummary/AnimationPlayer").play("Loss")
		get_node("SoundFX/Loss").play()


func end_round():
	RoundState = "Loading"
	var timer = get_node("CountdownTimer")
	timer.visible = false
	var balance = get_node("BalanceSheet")
	#balance.visible = false
	var cost = balance.cost
	var revenue = balance.revenue
	var cash = balance.cash
	var profit = revenue + cost # cost is negative
	balance.reset(cash + profit)
	show_summary(profit, cash + profit)
	# increase discount to make the next round harder
	if profit > 0:
		var BreakEvenDiscount = abs(cost) / revenue
		print("Cost/Revenue ratio: ", BreakEvenDiscount)
		var NewDiscount = DiscountCoef*0.75 + BreakEvenDiscount*0.25 # exponential smoothing
		print("Old discount: ", 100*(1-DiscountCoef), "%; ",
		      "New discount: ", 100*(1-NewDiscount), "%")
		DiscountCoef = NewDiscount
		Wheel.apply_discount(DiscountCoef)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "RocketLanding":
		RocketStatus = "Landed"
		Wheel.visible = true
		if RoundState == "BeginRound":
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




func _on_GameMenu_exit_game():
	get_tree().quit()


func _on_GameMenu_resume_game():
	GameMenu.hide()
	get_tree().paused = false


func _on_GameMenu_show_credits():
	GameMenu.hide()
	if CreditsPage:
		CreditsPage.show()
	else:
		get_tree().paused = false


func _on_CreditsPage_close_credits():
	CreditsPage.hide()
	GameMenu.show()
