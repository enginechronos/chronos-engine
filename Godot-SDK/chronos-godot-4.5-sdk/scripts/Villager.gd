extends Area2D

@onready var hud = get_node("../HUD/Message")


func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node) -> void:
	if body.name == "Player":
		hud.text = "Villager: Use the buttons to build reputation."


func _on_exit(body: Node) -> void:
	if body.name == "Player":
		hud.text = ""
