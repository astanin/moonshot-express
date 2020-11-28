extends Node2D

onready var CashDisplay = get_node("CashDisplay")
onready var CostDisplay = get_node("CostDisplay")
onready var RevenueDisplay = get_node("RevenueDisplay")

export var cash : float = 1234567
export var cost : float = -1234567
export var revenue : float = +1234567


func reset(newcash):
	cash = newcash
	cost = 0
	revenue = 0
	update_displays()


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
		n_s = " $" + n_s
	return n_s


func update_displays():
	CashDisplay.set_text(format_money(cash))
	if cost != 0:
		CostDisplay.set_text(format_money(cost))
		CostDisplay.visible = true
	else:
		CostDisplay.visible = false
	if revenue != 0:
		RevenueDisplay.set_text(format_money(revenue))
		RevenueDisplay.visible = true
	else:
		RevenueDisplay.visible = false


func set_cost(newcost):
	cost = newcost
	update_displays()


func increase_revenue(delta):
	revenue += delta
	update_displays()


# Called when the node enters the scene tree for the first time.
func _ready():
	reset(cash)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
