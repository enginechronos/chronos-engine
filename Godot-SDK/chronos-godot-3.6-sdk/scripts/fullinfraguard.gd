extends Area2D

var player_in := false
var mood := "neutral"

onready var hud = get_node("../HUD/Message")
onready var gate = get_node("../GateBlocker/CollisionShape2D")

const NPC_ID := "guard_1"


func _ready():
	connect("body_entered", self, "_on_enter")
	connect("body_exited", self, "_on_exit")

	# Server-authoritative updates from Chronos
	Chronos.connect("npc_state_updated", self, "_on_npc_state_updated")

	# Local fallback mood updates from demo script
	var rep = get_node("../HUD/ReputationActions")
	if rep:
		rep.connect("demo_mood_changed", self, "_on_demo_mood_changed")

	print("GUARD: requesting initial npc state...")
	Chronos.get_npc_state(NPC_ID)


func _on_enter(body):
	if body.name == "Player":
		player_in = true
		_show_dialog()


func _on_exit(body):
	if body.name == "Player":
		player_in = false
		hud.text = ""


# --------------------------------------------------
# Local fallback mood (instant UI)
# --------------------------------------------------
func _on_demo_mood_changed(new_mood):
	mood = str(new_mood)
	print("GUARD: demo mood applied →", mood)
	_apply_mood()


# --------------------------------------------------
# Server-authoritative mood
# --------------------------------------------------
func _on_npc_state_updated(row):
	if typeof(row) != TYPE_DICTIONARY:
		return
	if not row.has("npc_id") or not row.has("state"):
		return

	if str(row["npc_id"]) != NPC_ID:
		return

	var state = row["state"]
	if typeof(state) != TYPE_DICTIONARY:
		return

	# Defensive parsing for nested state shape
	if state.has("state") and typeof(state["state"]) == TYPE_DICTIONARY:
		state = state["state"]

	if state.has("mood"):
		mood = str(state["mood"])
		print("GUARD: mood updated from server →", mood)
		_apply_mood()
	else:
		print("GUARD: server state has no mood (empty projection)")


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
	# Gate blocks immediately when HOSTILE
	var block = (mood == "hostile")
	gate.disabled = not block

	if player_in:
		_show_dialog()
