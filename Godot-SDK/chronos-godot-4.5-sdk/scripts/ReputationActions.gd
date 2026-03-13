extends Node

# This signal is used only by the local demo scene so other nodes
# (like Guard.gd) can react immediately when Chronos sends updated state.
signal npc_demo_updated(row)

# Assign this in the Inspector to your visible message label.
# Example in this scene: ../Message
@export var message_label_path: NodePath
@onready var hud: Label = get_node_or_null(message_label_path)

# Which NPC this demo cares about
const NPC_ID: String = "guard_1"

# Prevent duplicate signal binding if the node is reloaded
var _bound: bool = false


func _ready() -> void:
	print("REPUTATION: SDK call example ready")

	# --------------------------------------------------
	# IMPORTANT CHRONOS CALL #1
	# Listen for live NPC state updates from Chronos.
	#
	# Why:
	# After your game sends an event, Chronos updates NPC state
	# and pushes it back through REST+SSE flow.
	# --------------------------------------------------
	if not _bound:
		if Chronos and not Chronos.npc_state_updated.is_connected(_on_npc_state_updated):
			Chronos.npc_state_updated.connect(_on_npc_state_updated)
		_bound = true

	# --------------------------------------------------
	# OPTIONAL CHRONOS CALL
	# Fetch the latest saved NPC state once on scene start.
	#
	# Why:
	# This hydrates the scene immediately when the game opens,
	# so the guard already knows the player's past reputation.
	# --------------------------------------------------
	if Chronos:
		Chronos.get_npc_state(NPC_ID)


func _on_npc_state_updated(row: Dictionary) -> void:
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
		var mood: String = str(state["mood"])
		_apply_guard_dialog(mood)

	# Forward this to other scene nodes such as Guard.gd
	npc_demo_updated.emit(row)


func _on_button_help_pressed() -> void:
	if hud:
		hud.text = "You helped a villager 🙂"

	_send_game_event("player_helped_villager", {
		"target": "villager_1"
	})


func _on_button_donate_pressed() -> void:
	if hud:
		hud.text = "You donated coins 💰"

	_send_game_event("player_donated_coin", {
		"amount": 5
	})


func _on_button_lie_pressed() -> void:
	if hud:
		hud.text = "You lied to the guard 😈"

	_send_game_event("player_lied_to_guard", {
		"context": "conversation"
	})


func _send_game_event(event_type: String, payload: Dictionary) -> void:
	# --------------------------------------------------
	# IMPORTANT CHRONOS CALL #2
	# Send a gameplay event into Chronos world memory.
	#
	# Why:
	# This is the main write call your game makes.
	# Chronos stores the event, auto-runs Brain (if configured),
	# then updates NPC state and sends the result back.
	# --------------------------------------------------
	if not Chronos:
		return

	Chronos.append_event(
		"player_1",   # who performed the action
		event_type,   # what happened
		payload,      # event details
		true          # significant event → can trigger Brain
	)


func _apply_guard_dialog(mood: String) -> void:
	if hud == null:
		return

	if mood == "friendly":
		hud.text = "Guard: Welcome, friend 🙂"
	elif mood == "suspicious":
		hud.text = "Guard: Hmm… I'm watching you."
	elif mood == "hostile":
		hud.text = "Guard: STOP. You're not allowed through!"
	else:
		hud.text = "Guard: Good day."
