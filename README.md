![Chronos Engine](images/chronos-banner.png)

# Chronos Engine

**Persistent World Memory for Games**

NPCs in most games forget everything.  
Chronos gives your game world **memory**.

Chronos Engine is a backend service that provides:

- persistent NPC memory  
- evolving world state  
- AI-driven behavior  

Instead of NPCs resetting every session, Chronos stores **world events** and derives NPC behavior from that history.

Player actions become part of the world's memory, allowing characters to react consistently across play sessions.

No more hardcoded NPC logic. Chronos turns player actions into persistent world memory.

---

## Overview

Chronos is like a **Magic Heart and a Living Mind** for video games.

Usually, characters in games are like actors who forget their lines as soon as you turn the game off.

Chronos gives them:

- **A Heart** → remembers their history forever  
- **A Mind** → thinks about those memories  

Example:

If you trick a guard today:

→ the **Heart remembers the lie**  
→ the **Mind processes the memory**  
→ the guard becomes **suspicious tomorrow**

Just plug Chronos into your game and the world begins to **learn, grow, and react like a living system**.

---

## What Chronos Does

Chronos stores **game events** and derives **NPC state** using rules and AI.

### Example Flow

```

Player steals from merchant
↓
Event stored in memory
↓
Chronos Brain processes memory
↓
Guard becomes suspicious
↓
NPC behavior changes

```

This creates **living worlds where actions have long-term consequences.**

---

# Architecture

Chronos uses a simple architecture designed for game engines.

```

Game Engine
│
▼
Chronos SDK
│
▼
Chronos API
│
▼
World Event Memory
│
▼
Chronos Brain
│
▼
NPC State
│
▼
Game reacts

```

Chronos stores every **significant action** as a world event, then derives the current NPC state from that history.

This architecture enables:

- persistent NPC memory  
- consistent world behavior  
- long-term player consequences  

---

# Demo

![Demo Scene](./images/demo-scene.png)

Watch the live demo:

https://chronos-magic-engine-live.vercel.app/demo/0.1v

### Demo Flow

```

Player performs an action
↓
Event stored in Chronos
↓
Chronos Brain processes memory
↓
NPC state updates
↓
NPC behavior changes
↓
Restart the game
↓
NPC still remembers

```

---

# Example Project

See the full working demo:

[https://github.com/enginechronos/chronos-demo]

The demo shows:

* Godot integration
* gameplay events
* NPC mood changes
* persistent world memory

---

## SDK Repositories

Chronos SDKs are maintained in separate repositories.

Start here if you want to integrate Chronos into your game.

Current:
- Godot SDK — https://github.com/enginechronos/chronos-godot-sdk

Upcoming:
- Unity SDK — coming soon
- Unreal Engine SDK — coming soon
- Roblox Studio SDK — coming soon

Each SDK repo contains engine-specific installation steps, setup guides, examples, and troubleshooting.

---

# API Basics

Chronos works with three core endpoints.

## Append Event

```
POST /api/events/append
```

Example:

```json
{
  "world_id": "village",
  "entity_id": "player_1",
  "event_type": "player_stole",
  "payload": {"npc":"merchant"},
  "significant": true
}
```

---

## Run Brain

```
POST /api/brain/think
```

---

## Fetch NPC State

```
GET /api/npc/state
```

Full documentation:

[https://chronos-magic-engine-live.vercel.app/docs]

---

# Vibe Console

Chronos includes a developer tool called the **Vibe Console**.

This allows developers to:

* inject events
* edit world rules
* inspect NPC state
* debug memory

You don’t need to change game code every time.

Adjust behavior directly from the console and NPCs will react immediately — no redeploy required.

Design NPC behavior **live while the game is running.**

---

### World Rule Editor

![World Rule](images/vibe-console-worldrule.png)

### NPC Event Debugging

![NPC Event](images/vibe-console-npcevent.png)

Without changing your game code, Chronos becomes a **live AI behavior control system** for your world.

---



# Engine Support

### Current

* Godot 3.6 SDK , Godot 4.5 SDK

### Comming

* Unity SDK
* Unreal Engine SDK
* JavaScript SDK

Chronos is designed to be **engine agnostic**.

---

# Why Chronos Exists

Most games reset NPC behavior every session.

Players may:

* steal
* lie
* attack
* help characters

But NPCs forget those actions when the game reloads.

Chronos solves this by giving game worlds **persistent memory**.

Every significant player action becomes part of the world's history, allowing NPCs to react consistently over time.

---

## Docs

- Product docs: https://chronos-magic-engine-live.vercel.app/docs
- Live demo: https://chronos-magic-engine-live.vercel.app/demo/0.1v


---

# Community

Building with Chronos?  
Have questions, feedback, or ideas?

Join the community or reach out directly.

### Discord (Developer Community)
[ https://discord.gg/Pg6Txu8YyB ]

### Chronos Updates (Project X)
[ https://x.com/EngineChronos ]

### Founder Contact
[ https://x.com/mr_manasmishra ]

---

# License

MIT License









