extends Node

# This signal is used only by the local demo scene so other nodes
# (like Guard.gd) can react immediately when Chronos sends updated state.
signal npc_demo_updated(row)

# Small local UI label for demo messages
onready var hud = get_node("../Message")

# Which NPC this demo cares about
const NPC_ID := "guard_1"


func _ready():
	print("REPUTATION:  SDK call example ready")

	# --------------------------------------------------
	# IMPORTANT CHRONOS CALL #1
	# Listen for live NPC state updates from Chronos.
	#
	# Why:
	# After your game sends an event, Chronos updates NPC state
	# and pushes it back through SSE.
	# --------------------------------------------------
	Chronos.connect("npc_state_updated", self, "_on_npc_state_updated")

	# --------------------------------------------------
	# OPTIONAL CHRONOS CALL
	# Fetch the latest saved NPC state once on scene start.
	#
	# Why:
	# This is useful if you want the scene to load the current
	# saved state immediately before new gameplay events happen.
	# --------------------------------------------------
	Chronos.get_npc_state(NPC_ID)


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

	# Defensive parsing in case the backend nests state
	if state.has("state") and typeof(state["state"]) == TYPE_DICTIONARY:
		state = state["state"]

	# Update demo UI using whatever your game expects.
	# This example uses "mood" because the demo world uses it.
	if state.has("mood"):
		var mood = str(state["mood"])
		_apply_guard_dialog(mood)

	# Forward the updated row so Guard.gd can react too
	emit_signal("npc_demo_updated", row)


# --------------------------------------------------
# BUTTON ACTIONS
# These simulate gameplay events.
# --------------------------------------------------

func _on_BtnHelp_pressed():
	hud.text = "You helped a villager 🙂"
	_send_game_event("player_helped_villager", {"target":"villager_1"})


func _on_BtnDonate_pressed():
	hud.text = "You donated coins 💰"
	_send_game_event("player_donated_coin", {"amount":5})


func _on_BtnLie_pressed():
	hud.text = "You lied to the guard 😈"
	_send_game_event("player_lied_to_guard", {"context":"conversation"})


# --------------------------------------------------
# CORE CHRONOS FLOW
# --------------------------------------------------
func _send_game_event(event_type: String, payload: Dictionary):
	# --------------------------------------------------
	# IMPORTANT CHRONOS CALL #2
	# Send a gameplay event into Chronos world memory.
	#
	# Why:
	# This is the main write call your game makes.
	# Chronos stores the event, auto-runs Brain (if configured),
	# updates NPC state, and pushes live state updates back.
	# --------------------------------------------------
	Chronos.append_event(
		"player_1",   # who did the action
		event_type,   # what happened
		payload,      # extra details
		true          # significant = important gameplay event
	)


func _apply_guard_dialog(mood: String):
	if mood == "friendly":
		hud.text = "Guard: Welcome, friend 🙂"
	elif mood == "suspicious":
		hud.text = "Guard: Hmm… I’m watching you."
	elif mood == "hostile":
		hud.text = "Guard: STOP. You’re not allowed through!"
	else:
		hud.text = "Guard: Good day."
