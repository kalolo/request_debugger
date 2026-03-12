# Request Debugger

A lightweight HTTP request inspection tool built with Phoenix LiveView. Send any HTTP request to the `/catch/*` endpoint and instantly see it appear on a real-time dashboard — useful for debugging webhooks, testing API integrations, or inspecting HTTP traffic.

## Features

- **Catch-all endpoint** — captures any HTTP method/path under `/catch/*`
- **Real-time dashboard** — requests appear instantly via LiveView (no polling)
- **Detailed inspection** — view headers, query params, body (raw + parsed), client IP, and more
- **Color-coded methods** — GET, POST, PUT, PATCH, DELETE each get a distinct color
- **Dark/light/system theme** toggle
- **Clear all** — reset captured requests with one click

## Getting Started

### Prerequisites

- Elixir ~> 1.19
- Erlang/OTP ~> 27

### Running locally

```bash
mix setup
mix phx.server
```

Visit [localhost:4000](http://localhost:4000) to open the dashboard, then send requests to `http://localhost:4000/catch/anything`:

```bash
curl -X POST http://localhost:4000/catch/my-webhook \
  -H "Content-Type: application/json" \
  -d '{"event": "test", "data": {"id": 1}}'
```

### Deploying to Fly.io

```bash
fly launch
fly deploy
```

## How It Works

1. Requests to `/catch/*` are captured by `CatchController` and stored in an in-memory Agent
2. A PubSub broadcast notifies the LiveView dashboard
3. The dashboard prepends the new request to the list in real time

Requests are stored in memory and reset on app restart.

## Tech Stack

- [Phoenix](https://www.phoenixframework.org/) 1.8 + [LiveView](https://hexdocs.pm/phoenix_live_view) 1.1
- [Tailwind CSS](https://tailwindcss.com/) + [DaisyUI](https://daisyui.com/)
- [Bandit](https://hexdocs.pm/bandit) web server
