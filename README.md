![Chronos Engine](images/chronos-banner.png)

# Chronos Engine

Persistent World Memory for Games.

Chronos Engine is a backend service that gives your game **persistent NPC memory, evolving world state, and AI-driven behavior**.

Instead of NPCs forgetting everything between sessions, Chronos lets them **remember events and react consistently over time.**


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

## Demo

![Demo Scene](images/demo-scene.png)


Watch the live demo:

https://chronos-magic-engine-live.vercel.app/demo/0.1v

This demo shows:

append events → run brain → fetch npc state

---

## Architecture

Chronos uses a simple architecture designed for game engines.


Game → SDK → Chronos API → Event Memory → Brain → NPC State → Game


Core concepts:

- **world_events** → append-only world history
- **npc_states** → derived NPC behavior
- **world_rules** → behavior rules
- **brain** → AI or deterministic logic
- **SSE stream** → real-time updates

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

### 3 Send events

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


### World Rule Editor
![World Rule](images/vibe-console-worldrule.png)

### NPC Event Debugging
![NPC Event](images/vibe-console-npcevent.png)

without changing your game code.


---

## Contributing

We welcome contributions.

Please read:

CONTRIBUTING.md

---

## Community

Discord:

https://discord.gg/pY5qTNAWV6

---

## License

MIT License

