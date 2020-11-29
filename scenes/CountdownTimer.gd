extends Node2D

onready var TimerCountdown = get_node("TimerCountdown")
onready var TimerTick = get_node("TimerTick")
onready var TimeDisplay = get_node("TimeDisplay")
var is_connected = false


signal count_zero


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func restart(timeout, MainScene):
	TimeDisplay.add_color_override("font_color", Color.white)
	TimerCountdown.start(timeout)
	if !is_connected:
		connect("count_zero", MainScene, "_on_CountdownTimer_count_zero")
		is_connected = true


func _on_TimerTick_timeout():
	var t = TimerCountdown.get_time_left()
	var t_str = "%05d" % (t * 1000)
	TimeDisplay.set_text(t_str)
	if t < 10:
		TimeDisplay.add_color_override("font_color", Color.crimson)


func _on_TimerSeconds_timeout():
	var t = TimerCountdown.get_time_left()
	if t <= 10 and t > 0:
		get_node("Beep").play()


func _on_TimerCountdown_timeout():
	TimerCountdown.stop()
	emit_signal("count_zero")



