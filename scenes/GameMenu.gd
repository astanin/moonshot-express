extends Control

onready var ResumeButton = get_node("MenuBg/ResumeButton")
var menu_pressed = false

signal resume_game

signal exit_game

signal show_credits


# Called when the node enters the scene tree for the first time.
func _ready():
	ResumeButton.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !visible:
		return

	var focus = get_focus_owner()
	if Input.is_action_just_pressed("ui_accept"):
		var name = focus.name
		if name == "ExitButton":
			emit_signal("exit_game")
		elif name == "ResumeButton":
			emit_signal("resume_game")
	elif Input.is_action_just_released("game_menu") and menu_pressed:
		emit_signal("resume_game")
	elif Input.is_action_just_pressed("game_menu"):
		menu_pressed = true


func _on_GameMenu_visibility_changed():
	if visible:
		ResumeButton.grab_focus()
		menu_pressed = false
