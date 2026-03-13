extends CharacterBody2D

@export var speed: float = 250.0


func _ready() -> void:
	print("PLAYER READY: script running")


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1.0

	dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()
