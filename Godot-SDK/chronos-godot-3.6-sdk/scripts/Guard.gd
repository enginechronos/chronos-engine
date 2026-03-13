extends Area2D

var player_in := false
var mood := "neutral"

onready var hud = get_node("../HUD/Message")
onready var gate = get_node("../GateBlocker/CollisionShape2D")

const NPC_ID := "guard_1"


func _ready():
	connect("body_entered", self, "_on_enter")
	connect("body_exited", self, "_on_exit")

	# --------------------------------------------------
	# Listen for demo-forwarded NPC updates.
	#
	# Why:
	# ReputationActions.gd already listens to Chronos directly
	# and forwards updated NPC rows to other scene logic.
	# --------------------------------------------------
	var rep = get_node("../HUD/ReputationActions")
	if rep:
		rep.connect("npc_demo_updated", self, "_on_npc_demo_updated")


func _on_enter(body):
	if body.name == "Player":
		player_in = true
		_show_dialog()


func _on_exit(body):
	if body.name == "Player":
		player_in = false
		hud.text = ""


func _on_npc_demo_updated(row):
	if typeof(row) != TYPE_DICTIONARY:
		return
	if not row.has("npc_id") or not row.has("state"):
		return

	if str(row["npc_id"]) != NPC_ID:
		return

	var state = row["state"]
	if typeof(state) != TYPE_DICTIONARY:
		return

	if state.has("state") and typeof(state["state"]) == TYPE_DICTIONARY:
		state = state["state"]

	if state.has("mood"):
		mood = str(state["mood"])
		_apply_mood()


func _show_dialog():
	if mood == "friendly":
		hud.text = "Guard: Welcome, friend 🙂"
	elif mood == "suspicious":
		hud.text = "Guard: Hmm… I’m watching you."
	elif mood == "hostile":
		hud.text = "Guard: STOP. You’re not allowed through!"
	else:
		hud.text = "Guard: Good day."


func _apply_mood():
	var block = (mood == "hostile")
	gate.disabled = not block

	if player_in:
		_show_dialog()
