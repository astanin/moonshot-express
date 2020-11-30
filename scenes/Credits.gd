extends Control

onready var ResumeButton = get_node("CreditsBg/ResumeButton")

signal close_credits

var ui_accept_pressed = false


# Called when the node enters the scene tree for the first time.
func _ready():
	ResumeButton.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !visible:
		return
	
	if Input.is_action_just_released("ui_accept") and ui_accept_pressed:
		emit_signal("close_credits")
	elif Input.is_action_just_pressed("ui_accept"):
		ui_accept_pressed = true


func _on_Credits_visibility_changed():
	ResumeButton.grab_focus()
	ui_accept_pressed = false
