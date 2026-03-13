extends Area2D
onready var hud = get_node("../HUD/Message")

func _ready():
	connect("body_entered", self, "_on_enter")
	connect("body_exited", self, "_on_exit")

func _on_enter(body):
	if body.name == "Player":
		hud.text = "Villager: Use the buttons to build reputation."

func _on_exit(body):
	if body.name == "Player":
		hud.text = ""
