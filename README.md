# LLM Proxy

LiteLLM proxy with Tailscale networking for routing Claude API requests. Supports multiple Claude models with automatic failover across multiple remote LiteLLM instances.

## Architecture

```
Claude CLI / SDK  -->  LiteLLM Proxy (localhost:4000)  -->  Anthropic API
                              |
                              +--> Tailscale VPN (private mesh)
                              |
                              +--> Remote 1 (fallback)
                              +--> Remote 2 (fallback)
```

## Setup

1. **Copy environment file and fill in your values:**

```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `TS_AUTHKEY` | Tailscale auth key from [admin console](https://login.tailscale.com/admin/settings/keys) |
| `TS_HOSTNAME` | Tailscale hostname for this node |
| `ANTHROPIC_API_KEY` | Anthropic API key (same as `CLAUDE_PRO_TOKEN`) |
| `CLAUDE_PRO_TOKEN` | Anthropic API key used by model configs |
| `LITELLM_MASTER_KEY` | Master key for accessing the proxy (use as `ANTHROPIC_API_KEY` in clients) |
| `REMOTE_1_KEY` | API key for remote LiteLLM instance 1 |
| `REMOTE_1_BASE` | URL of remote LiteLLM instance 1 |
| `REMOTE_2_KEY` | API key for remote LiteLLM instance 2 |
| `REMOTE_2_BASE` | URL of remote LiteLLM instance 2 |

2. **Build and start:**

```bash
make rebuild
```

3. **Verify it's running:**

```bash
make health
```

## Usage

### With Claude CLI

```bash
export ANTHROPIC_BASE_URL=http://localhost:4000
export ANTHROPIC_API_KEY=<your LITELLM_MASTER_KEY>
claude
```

### Local models (direct to Anthropic)

```bash
claude --model claude-sonnet-4-6
claude --model claude-opus-4-7
claude --model claude-haiku-4-5
```

### Remote models (via remote LiteLLM instances)

Use `remote-{n}/{model}` to route through a specific remote instance:

```bash
claude --model remote-1/claude-sonnet-4-6   # sonnet on remote 1
claude --model remote-1/claude-opus-4-7     # opus on remote 1
claude --model remote-2/claude-haiku-4-5    # haiku on remote 2
```

Any model name supported by the remote LiteLLM instance can be used after the `remote-{n}/` prefix.

### With curl

```bash
make test
```

## Available Models

| Model name | Routes to |
|---|---|
| `claude-opus-4-7` | Anthropic Claude Opus 4.7 (direct) |
| `claude-sonnet-4-6` | Anthropic Claude Sonnet 4.6 (direct) |
| `claude-haiku-4-5` | Anthropic Claude Haiku 4.5 (direct) |
| `remote-1/{model}` | Any model via remote instance 1 |
| `remote-2/{model}` | Any model via remote instance 2 |

## Commands

| Command | Description |
|---|---|
| `make build` | Build the Docker image |
| `make up` | Start the container |
| `make down` | Stop the container |
| `make restart` | Stop and start |
| `make rebuild` | Stop, rebuild, and start |
| `make logs` | Tail container logs (stdout) |
| `make logs-file` | Tail LiteLLM request log file |
| `make health` | Check proxy health |
| `make models` | List available models |
| `make test` | Send a test message |

## Failover

If a local model fails, requests automatically fall back through the remote instances in order:

```
claude-opus-4-7  -->  remote-1/claude-opus-4-7  -->  remote-2/claude-opus-4-7
claude-sonnet-4-6  -->  remote-1/claude-sonnet-4-6  -->  remote-2/claude-sonnet-4-6
claude-haiku-4-5  -->  remote-1/claude-haiku-4-5  -->  remote-2/claude-haiku-4-5
```

Each request is retried up to 2 times with a 5s delay before moving to the next fallback.

## Adding more remotes

1. Add env vars to `.env`:
```
REMOTE_3_KEY=sk-xxxx
REMOTE_3_BASE=http://remote-host-3:4000
```

2. Add a model entry to `config.yaml`:
```yaml
  - model_name: "remote-3/*"
    litellm_params:
      model: "openai/*"
      api_key: "os.environ/REMOTE_3_KEY"
      api_base: "os.environ/REMOTE_3_BASE"
      drop_params: true
```

3. Add to the fallback chain in `router_settings.fallbacks`.

4. `make restart`

## No Database

This proxy runs without a database (`allow_requests_on_db_unavailable: true`). This means no spend tracking, budget enforcement, or virtual key management. Only the master key is used for authentication. This is acceptable when the proxy is not exposed to the public internet (behind Tailscale).
