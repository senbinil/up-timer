# Broadcasting Architecture

> Real-time updates for the dashboard and public status page using Turbo Streams, Solid Cable, and a cursor-based deduplication mechanism.

---

## Overview

UpTimer uses **Hotwire's Turbo Streams** over **Action Cable** (backed by Solid Cable) to push live updates to connected browsers. Two channels — `"dashboard"` and `"public_status"` — keep the UI in sync as monitors are checked, statuses change, and alerts fire.

```
                  ┌─────────────────┐
                  │  Recurring Jobs │
                  │  (every 2s)     │
                  └────────┬────────┘
                           │
                  ┌────────▼────────┐
                  │DashboardBroadcast│
                  │      Job        │
                  │  (cursor-based) │
                  └────────┬────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
     ┌────────▼───┐ ┌─────▼─────┐ ┌────▼─────────┐
     │ Dashboard  │ │  Status   │ │  Shared      │
     │ Broadcast  │ │  Page     │ │  Cursor      │
     │ Service    │ │  Broadcast│ │  (Rails.cache)│
     │            │ │  Service  │ │              │
     └────────┬───┘ └─────┬─────┘ └────▲─────────┘
              │            │            │
              └─────┬──────┘            │
                    │                   │
         ┌──────────▼──────────┐        │
         │  Turbo::Streams      │        │
         │  Channel             │        │
         │  .broadcast_stream_to│        │
         └──────────┬───────────┘        │
                    │                    │
         ┌──────────▼───────────┐        │
         │  Solid Cable         │        │
         │  (Action Cable       │        │
         │   adapter)           │        │
         └──────────┬───────────┘        │
                    │                    │
         ┌──────────▼───────────┐        │
         │  Browser (Turbo)     │        │
         │  receives Stream     │        │
         │  & replaces DOM      │        │
         └──────────────────────┘        │
                                          │
     ┌────────────────────────────────────┘
     │
     │  On each successful broadcast,
     │  the cursor is advanced so the
     │  next tick only picks up new data.
```

---

## Recurring Schedule

Defined in `config/recurring.yml`:

| Job                     | Interval     | Purpose                                                 |
| ----------------------- | ------------ | ------------------------------------------------------- |
| `MonitorSchedulerJob`   | Every 30s    | Enqueues individual checks for monitors due for recheck |
| `DashboardBroadcastJob` | Every 2s     | Polls for recent changes and broadcasts them            |
| `DataRetentionJob`      | Daily at 3am | Purges old checks and resolved incidents                |

The `DashboardBroadcastJob` runs independently of the monitor scheduler, acting as a **polling loop**. Every 2 seconds it queries for any new data since the last broadcast.

---

## The Shared Cursor

The cursor is the core mechanism that ensures broadcasts are **idempotent, lossless, and efficient**.

### How it works

```ruby
# app/jobs/dashboard_broadcast_job.rb
class DashboardBroadcastJob < ApplicationJob
  CURSOR_KEY = "dashboard:last_broadcast_at"
  FALLBACK_WINDOW = 5.seconds

  def perform
    # 1. Read the cursor from shared cache
    cursor = Rails.cache.read(CURSOR_KEY) || FALLBACK_WINDOW.ago

    # 2. Query for new data since cursor
    checked_monitor_ids = MonitorCheck
      .where(checked_at: cursor..)
      .distinct
      .pluck(:monitor_id)

    new_alerts = Alert
      .where(created_at: cursor..)
      .recent
      .to_a

    # Skip if nothing changed
    return if checked_monitor_ids.empty? && new_alerts.empty?

    # 3. Broadcast both dashboard and public status page
    DashboardBroadcastService.call(updated_nodes: updated_nodes, new_alerts: new_alerts)
    StatusPageBroadcastService.call(updated_nodes: updated_nodes, new_alerts: new_alerts)

    # 4. Advance the cursor
    Rails.cache.write(CURSOR_KEY, Time.current)
  end
end
```

### Key properties

| Property       | Description                                                                                                                                             |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Shared**     | Both dashboard and public status page broadcasts use the same cursor — a single timestamp in `Rails.cache`.                                             |
| **Time-based** | The cursor stores `Time.current` after each successful broadcast. The next tick queries for records with `created_at` / `checked_at` >= that timestamp. |
| **Idempotent** | If two job ticks run simultaneously, the second will find no new records (cursor hasn't advanced) and skip.                                             |
| **Lossless**   | Even if a tick is missed, the next tick picks up everything since the last cursor position.                                                             |
| **Fallback**   | If the cache is empty (first run or evicted), it falls back to `5.seconds.ago`, ensuring recent data is still picked up.                                |

---

## Dual-Channel Broadcasting

A single `DashboardBroadcastJob` tick broadcasts to **both** channels:

### 1. Dashboard Channel (`"dashboard"`)

- **Subscribed by:** `app/views/dashboard/index.html.erb` → `<%= turbo_stream_from "dashboard" %>`
- **Broadcast template:** `app/views/dashboard/broadcast.turbo_stream.erb`
- **Frontend controller:** `dashboard_receiver_controller.js` (re-initializes Chartkick charts after Turbo renders)

**What gets updated:**

```
alerts (prepend new alert rows)
  ↓
node cards (replace each updated node's card)
  ↓
fleet status (replace global stats summary)
```

Updates are ordered so that alert counts flow correctly into the fleet status panel.

### 2. Public Status Channel (`"public_status"`)

- **Subscribed by:** `app/views/home/show.html.erb` → `<%= turbo_stream_from "public_status" %>`
- **Broadcast template:** `app/views/home/broadcast.turbo_stream.erb`

**What gets updated:**

```
fleet status (replace public system status card)
  ↓
node detail elements (replace each public node's <details>)
  ↓
alert rows (prepend new alerts)
```

Only **public-listed** monitors are broadcast to this channel. The `StatusPageBroadcastService` filters `@updated_nodes` to those where `public_listed?` is true.

---

## Broadcast Flow (Detailed)

```
Timer tick (every 2s)
  │
  ├─ DashboardBroadcastJob#perform
  │     │
  │     ├─ Read cursor from Rails.cache
  │     │
  │     ├─ Query MonitorCheck.where(checked_at: cursor..)
  │     │     └─ distinct monitor_ids → updated_nodes
  │     │
  │     ├─ Query Alert.where(created_at: cursor..)
  │     │     └─ new_alerts
  │     │
  │     ├─ If nothing found → return (skip)
  │     │
  │     ├─ DashboardBroadcastService.call(updated_nodes, new_alerts)
  │     │     │
  │     │     ├─ Render app/views/dashboard/broadcast.turbo_stream.erb
  │     │     │     using ApplicationController.render (no HTTP round-trip)
  │     │     │
  │     │     └─ Turbo::StreamsChannel.broadcast_stream_to("dashboard", content: html)
  │     │           └─ Solid Cable → Action Cable → Connected browsers
  │     │
  │     ├─ StatusPageBroadcastService.call(updated_nodes, new_alerts)
  │     │     │
  │     │     ├─ Filter to public_listed nodes only
  │     │     ├─ Render app/views/home/broadcast.turbo_stream.erb
  │     │     └─ Turbo::StreamsChannel.broadcast_stream_to("public_status", content: html)
  │     │
  │     └─ Rails.cache.write(CURSOR_KEY, Time.current)
  │
  └─ End
```

---

## Why Only the Cursor-Based Job?

Previously, `MonitorCheckJob` also fired a broadcast **immediately** after each individual check. This was removed because the cursor-based `DashboardBroadcastJob` (every 2s) made it redundant:

| Aspect                    | Cursor job (every 2s)              | Per-check broadcast               |
| ------------------------- | ---------------------------------- | --------------------------------- |
| **Coverage**              | Both dashboard + public status     | Dashboard only                    |
| **Latency**               | ≤ 2s (negligible for 30s+ checks)  | Immediate                         |
| **Batching**              | Batches updates into one broadcast  | One broadcast per check           |
| **Reliability**           | Cursor tracks position precisely   | Hardcoded 5-second alert window   |

Removing the per-check broadcast reduced cable traffic and simplified `MonitorCheckJob` to a single responsibility — performing the check and persisting results.

---

## Server-Side Rendering

Both broadcast services render HTML on the server side using `ApplicationController.render`:

```ruby
html = ApplicationController.render(
  template: "dashboard/broadcast",
  layout: false,
  assigns: {
    updated_nodes: @updated_nodes,
    new_alerts: @new_alerts,
    stats: stats,
    alert_counts: alert_counts
  }
)
```

This approach:

- Avoids an HTTP round-trip — rendering happens entirely in-process
- Reuses existing partials and helpers
- Produces a complete HTML string that Turbo applies directly to the DOM

---

## Frontend Reception

### Turbo Stream subscription

Both views subscribe via the `turbo_stream_from` helper, which establishes an Action Cable consumer:

```erb
<%# dashboard/index.html.erb %>
<%= turbo_stream_from "dashboard" %>

<%# home/show.html.erb %>
<%= turbo_stream_from "public_status" %>
```

### Stimulus controller (`dashboard_receiver_controller.js`)

```javascript
// app/javascript/controllers/dashboard_receiver_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	connect() {
		this.boundRedraw = this.redrawCharts.bind(this);
		document.addEventListener("turbo:render", this.boundRedraw);
	}

	disconnect() {
		document.removeEventListener("turbo:render", this.boundRedraw);
	}

	redrawCharts() {
		if (window.Chartkick) {
			window.Chartkick.charts = {}; // Clear stale chart instances
		}
	}
}
```

This controller:

- Attached to `<main data-controller="dashboard-receiver">` in the dashboard layout
- Listens for `turbo:render` events (fired after Turbo applies stream updates)
- Re-initializes Chartkick charts that may have been stale after DOM replacement
- Not attached to the public status page (no charts there)

---

## Infrastructure Layer

### Action Cable adapter

Configured in `config/cable.yml`:

```yaml
development:
  adapter: solid_cable
  # ...
```

Solid Cable is a database-backed Action Cable adapter. Messages are stored in the `solid_cable_messages` table and polled by connected clients. This eliminates the need for Redis or any other external pub/sub service.

### Cache store

The cursor is stored in `Rails.cache`. In development, this defaults to `:memory_store`. In production, it uses `:solid_cache` (also database-backed), keeping infrastructure requirements minimal.

---

## Data Flow Diagram (Complete)

```
┌──────────────┐     ┌──────────────────┐
│  User Action  │     │  Recurring Timer  │
│  (pause,      │     │  (every 2s)      │
│   resolve,    │     │                  │
│   create)     │     │                  │
└──────┬───────┘     └───────┬──────────┘
       │                     │
       └─────────┬───────────┘
                 │
       ┌─────────▼─────────┐
       │  DashboardBroadcast│
       │  Job (cursor-based)│
       └─────────┬─────────┘
                 │
       ┌─────────▼──────────┐
       │  Render broadcast  │
       │  templates → HTML  │
       └─────────┬──────────┘
                 │
              ┌──┴──┐
              │     │
     ┌────────▼────┐ │  ┌─────────────┐
     │ Turbo Stream│ │  │ Advance     │
     │ to          │ │  │ Cursor in   │
     │ "dashboard" │ │  │ Rails.cache │
     └────────┬────┘ │  └─────────────┘
              │      │
     ┌────────▼────┐ │
     │ Turbo Stream│ │
     │ to          │ │
     │"public_status│ │
     └────────┬────┘ │
              │      │
              ▼      ▼
        ┌──────────────────────────┐
        │    Solid Cable           │
        │  (Action Cable adapter)  │
        │  stores in DB table      │
        └────────────┬─────────────┘
                     │
        ┌────────────▼─────────────┐
        │  Connected Browsers      │
        │                          │
        │  Turbo receives stream   │
        │  Applies DOM changes     │
        │  Fires turbo:render      │
        │  → dashboard_receiver    │
        │    redraws charts        │
        └──────────────────────────┘
```

---

## Configuration Files

| File                   | Purpose                                                                                                               |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `config/recurring.yml` | Defines the recurring Solid Queue schedule for `DashboardBroadcastJob`, `MonitorSchedulerJob`, and `DataRetentionJob` |
| `config/cable.yml`     | Configures Solid Cable as the Action Cable adapter                                                                    |
| `config/cache.yml`     | Configures Solid Cache as the cache store                                                                             |

---

## Key Files Reference

| File                                                          | Role                                              |
| ------------------------------------------------------------- | ------------------------------------------------- |
| `app/jobs/dashboard_broadcast_job.rb`                         | Cursor-based polling loop (runs every 2s)         |
| `app/services/dashboard_broadcast_service.rb`                 | Renders & broadcasts dashboard Turbo Stream       |
| `app/services/status_page_broadcast_service.rb`               | Renders & broadcasts public status Turbo Stream   |
| `app/jobs/monitor_check_job.rb`                               | Per-check broadcast (immediate, dashboard only)   |
| `app/views/dashboard/broadcast.turbo_stream.erb`              | Dashboard Turbo Stream template                   |
| `app/views/home/broadcast.turbo_stream.erb`                   | Public status Turbo Stream template               |
| `app/views/dashboard/index.html.erb`                          | Subscribes to `"dashboard"` channel               |
| `app/views/home/show.html.erb`                                | Subscribes to `"public_status"` channel           |
| `app/views/layouts/dashboard.html.erb`                        | Attaches `dashboard-receiver` Stimulus controller |
| `app/javascript/controllers/dashboard_receiver_controller.js` | Re-initializes Chartkick after Turbo updates      |
| `config/recurring.yml`                                        | Recurring job schedule                            |
