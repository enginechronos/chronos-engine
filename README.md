![Chronos Engine](images/chronos-banner.png)

# Chronos Engine

Persistent World Memory Infrastructure for Games

NPCs in most games forget everything.
Chronos gives your game world memory.

Chronos Engine is a backend service that gives your game persistent NPC memory, evolving world state, and AI-driven behavior.

Instead of NPCs resetting every session, Chronos stores world events and derives NPC behavior from that history.

Player actions become part of the world’s memory, allowing characters to react consistently across play sessions.


# Overview

Chronos is like a "Magic Heart and a Living Mind" for video games. Usually, characters in games are like actors who forget their lines as soon as you turn the game off. Chronos gives them a Heart to remember their history forever and a Mind to think about those memories. If you trick a guard today, his Heart remembers the lie, and his Mind decides to be suspicious when you log in tomorrow. You just plug Chronos into any game, and the world starts to learn, grow, and react to you just like a living person would.

---

## What Chronos Does

Chronos stores game events and derives NPC state using rules & AI.

Example flow:

Player steals from merchant  
→ event stored in memory  
→ NPC brain processes memory  
→ guard becomes suspicious  
→ NPC behavior changes

This creates **living worlds where actions have long-term consequences.**

---

## Architecture

Chronos uses a simple architecture designed for game engines.


Game Engine
   ↓
Chronos SDK
   ↓
Chronos API
   ↓
World Event Memory
   ↓
Chronos Brain
   ↓
NPC State
   ↓
Game reacts


Chronos stores every significant action as a world event, then derives the current NPC state from that history.

This architecture allows:

persistent NPC memory

consistent world behavior

long-term player consequences

---

## Demo

![Demo Scene](images/demo-scene.png)


Watch the live demo:

https://chronos-magic-engine-live.vercel.app/demo/0.1v

The demo shows:

Player performs an action

Event is stored in Chronos

Chronos Brain processes memory

NPC state updates

NPC behavior changes

Restart the game and the NPC still remembers.

---


## Quick Start

### 1 Install SDK

Copy the Godot SDK into your project:


res://addons/chronos/


Files:


Chronos.gd
ChronosRESTClient.gd
ChronosSSEClient.gd
ChronosTypes.gd


Enable the plugin in:


Project Settings → Plugins


---

### 2 Configure Chronos

```
Chronos.configure(
"https://chronos-engine.vercel.app
",
"CHRONOS_API_KEY",
"your_world_id",
"npc_id"
)

Chronos.start()
```

---

Recommended SDK Flow (MVP)

Your game only needs to send events and listen for NPC state updates.
Chronos automatically runs the Brain and pushes real-time state updates.

Important Call 1 — Listen for NPC state updates
Chronos.npc_state_updated.connect(_on_npc_state_updated)

```
func _on_npc_state_updated(row):

  var npc_id = row["npc_id"]
  var state = row["state"]

  print("NPC state updated:", npc_id, state)

```  

Your game reacts to NPC behavior changes here.

Important Call 2 — Send gameplay events

When something important happens in your game, send it to Chronos.

```
Chronos.append_event(
  "player_1",
  event_type,
  payload,
  true
)

```

Example:

Chronos.append_event(
  "player_1",
  "player_lied_to_guard",
  {"context":"conversation"},
  true
)

Chronos will automatically:

store the event

run the Brain

update NPC state

push the update back to the game

Optional Call — Load saved NPC state on startup (recommended)

If a scene loads after a restart, you may want to fetch the saved NPC state once.

Chronos.get_npc_state("guard_1")

This ensures the NPC immediately reflects the saved world state.

---

```
Chronos.append_event(
"player_1",
"player_lied_to_guard",
{"context":"conversation"},
true
)

Chronos.brain_think(50)

Chronos.get_npc_state("guard_1")
```

---

## Example Project

See the full working demo:

https://github.com/enginechronos/chronos-demo

The demo shows:

- Godot integration
- gameplay events
- NPC mood changes
- persistent world memory

---

## API Basics

Chronos works with three core endpoints.

Append Event


POST /api/events/append

Example:

{
  "world_id": "village",
  "entity_id": "player_1",
  "event_type": "player_stole",
  "payload": {"npc":"merchant"},
  "significant": true
}


Run Brain


POST /api/brain/think


Fetch NPC State


GET /api/npc/state


Full docs:

https://chronos-magic-engine-live.vercel.app/docs

---

## Vibe Console

Chronos includes a developer tool called the **Vibe Console**.

This lets you:

- inject events
- edit world rules
- inspect NPC state
- debug memory

You don’t need to change game code every time.
Adjust behavior directly from the console and your NPCs will react immediately — no hardcoding or redeploy required.

Design your NPC behavior live while the game is running.

### World Rule Editor
![World Rule](images/vibe-console-worldrule.png)

### NPC Event Debugging
![NPC Event](images/vibe-console-npcevent.png)

Without changing your game code, Chronos becomes a live AI behavior control system for your world.

---

Engine Support

Current:

Godot 3.6 SDK

Planned:

Unity SDK

Unreal Engine SDK

JavaScript SDK

Chronos is designed to be engine agnostic.

---

Why Chronos Exists

Most games reset NPC behavior every session.

Players may steal, lie, attack, or help characters — but NPCs forget those actions once the game reloads.

Chronos solves this by giving game worlds persistent memory.

Every significant player action becomes part of the world’s history, allowing NPCs to react consistently over time.

---

Roadmap

Upcoming work includes:

improved runtime streaming

Unity SDK

multi-NPC world simulations

deeper AI behavior systems

advanced world orchestration

Chronos aims to become the memory layer for living game worlds.

---

## Community

Discord:

https://discord.gg/pY5qTNAWV6

---

## License

MIT License

