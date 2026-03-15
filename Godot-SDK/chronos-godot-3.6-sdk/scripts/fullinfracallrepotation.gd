extends Node

# Signal emitted so other nodes (Guard) can react to fallback mood updates
signal demo_mood_changed(mood)

# Reference to HUD label used for messages
onready var hud = get_node("../Message")

# Local demo variable (NON-persistent)
# Used only as fallback if server state is not yet available
var reputation_score := 0


func _ready():
	print("REPUTATION: system ready")

	# Listen for Chronos responses and state updates
	Chronos.connect("request_ok", self, "_on_ok")
	Chronos.connect("request_err", self, "_on_err")
	Chronos.connect("npc_state_updated", self, "_on_npc_state_updated")


# --------------------------------------------------
# Chronos callbacks
# --------------------------------------------------

func _on_ok(tag, data):
	# Keep this for visibility/debug logs
	if tag == "events.append":
		print("[Chronos OK] events.append", data)
	elif tag == "brain.think":
		print("[Chronos OK] brain.think", data)
	elif tag == "npc.state":
		print("[Chronos OK] npc.state", data)
	elif tag == "rules.set":
		print("[Chronos OK] rules.set")
	elif tag == "rules.get":
		print("[Chronos OK] rules.get", data)


func _on_err(tag, code, message, _raw):
	print("[Chronos ERR]", tag, code, message)

	# Free-tier / quota feedback
	if int(code) == 429:
		hud.text = "Rate limited. Try again in ~60s."


# Server-authoritative NPC state
func _on_npc_state_updated(row):
	if typeof(row) != TYPE_DICTIONARY:
		return
	if not row.has("npc_id") or not row.has("state"):
		return

	# This demo only cares about guard_1
	if str(row["npc_id"]) != "guard_1":
		return

	var state = row["state"]
	if typeof(state) != TYPE_DICTIONARY:
		return

	# Defensive parsing: sometimes state can be nested
	if state.has("state") and typeof(state["state"]) == TYPE_DICTIONARY:
		state = state["state"]

	if state.has("mood"):
		var mood = str(state["mood"])
		print("[NPC STATE UPDATED] mood =", mood)

		_apply_guard_dialog(mood)
		emit_signal("demo_mood_changed", mood)
	else:
		print("REPUTATION: server state has no mood, using fallback only.")


# --------------------------------------------------
# BUTTON ACTIONS (GAMEPLAY EVENTS)
# --------------------------------------------------

func _on_BtnHelp_pressed():
	# Immediate UI feedback
	hud.text = "You helped a villager 🙂"

	# Local fallback logic
	reputation_score += 1

	_send_event(
		"player_helped_villager",
		{"target":"villager_1"}
	)


func _on_BtnDonate_pressed():
	hud.text = "You donated coins 💰"
	reputation_score += 2

	_send_event(
		"player_donated_coin",
		{"amount":5}
	)


func _on_BtnLie_pressed():
	hud.text = "You lied to the guard 😈"

	# Local fallback logic
	reputation_score = -3

	_send_event(
		"player_lied_to_guard",
		{"context":"conversation"}
	)


# --------------------------------------------------
# CORE CHRONOS FLOW (PLUG-AND-PLAY)
# --------------------------------------------------

func _send_event(event_type: String, payload: Dictionary):
	# Send gameplay event → Chronos Memory Engine
	#
	# New Phase 3 behavior:
	# append_event(significant=true) will auto-trigger brain_think() inside the SDK
	# and SSE should push npc_state_updated back to the game.
	Chronos.append_event(
		"player_1",
		event_type,
		payload,
		true
	)

	# --------------------------------------------------
	# LOCAL DEMO FALLBACK
	# --------------------------------------------------
	# We still apply a quick local mood so the demo feels responsive even
	# if server/SSE is slow or AI fallback is temporarily unavailable.
	var mood = _mood_from_score()
	_apply_guard_dialog(mood)
	emit_signal("demo_mood_changed", mood)


# --------------------------------------------------
# LOCAL DEMO LOGIC (NON-PERSISTENT)
# --------------------------------------------------

func _mood_from_score() -> String:
	if reputation_score >= 3:
		return "friendly"

	if reputation_score <= -3:
		return "hostile"

	if reputation_score < 0:
		return "suspicious"

	return "neutral"


func _apply_guard_dialog(mood: String):
	if mood == "friendly":
		hud.text = "Guard: Welcome, friend 🙂"
	elif mood == "suspicious":
		hud.text = "Guard: Hmm… I’m watching you."
	elif mood == "hostile":
		hud.text = "Guard: STOP. You’re not allowed through!"
	else:
		hud.text = "Guard: Good day."
