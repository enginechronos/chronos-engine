extends Area2D

var player_in: bool = false
var mood: String = "neutral"

@onready var hud = get_node("../HUD/Message")
@onready var gate = get_node("../GateBlocker/CollisionShape2D")

const NPC_ID: String = "guard_1"


func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

	# --------------------------------------------------
	# NO DIRECT SDK CALL HERE
	#
	# Guard.gd does not talk to Chronos directly.
	# Instead, ReputationActions.gd listens to Chronos and
	# forwards updated NPC state to this node.
	#
	# Game UI sends events → Chronos updates memory →
	# scene gameplay reacts to updated state.
	# --------------------------------------------------
	var rep = get_node_or_null("../HUD/ReputationActions")
	if rep:
		rep.npc_demo_updated.connect(_on_npc_demo_updated)


func _on_enter(body: Node) -> void:
	if body.name == "Player":
		player_in = true
		_show_dialog()


func _on_exit(body: Node) -> void:
	if body.name == "Player":
		player_in = false
		hud.text = ""


func _on_npc_demo_updated(row: Dictionary) -> void:
	if not row.has("npc_id") or not row.has("state"):
		return

	if str(row["npc_id"]) != NPC_ID:
		return

	var state = row["state"]
	if not (state is Dictionary):
		return

	# Defensive parse in case backend wraps the state again
	if state.has("state") and state["state"] is Dictionary:
		state = state["state"]

	if state.has("mood"):
		mood = str(state["mood"])
		_apply_mood()


func _show_dialog() -> void:
	if mood == "friendly":
		hud.text = "Guard: Welcome, friend 🙂"
	elif mood == "suspicious":
		hud.text = "Guard: Hmm… I’m watching you."
	elif mood == "hostile":
		hud.text = "Guard: STOP. You’re not allowed through!"
	else:
		hud.text = "Guard: Good day."


func _apply_mood() -> void:
	# hostile = gate blocked
	# friendly / suspicious / neutral = gate open
	var block := mood == "hostile"
	gate.disabled = not block

	if player_in:
		_show_dialog()
