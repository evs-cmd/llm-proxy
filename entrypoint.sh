#!/bin/bash
set -e

# Start Tailscale daemon in userspace mode (essential for Docker on Mac)
/usr/sbin/tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Give the daemon a moment to breathe
sleep 2

# Authenticate with Tailscale
# TS_AUTHKEY and TS_HOSTNAME are passed from docker-compose.yaml
echo "Connecting to Tailscale as ${TS_HOSTNAME}..."
/usr/bin/tailscale up --authkey="${TS_AUTHKEY}" --hostname="${TS_HOSTNAME}" --accept-dns=true

# Start LiteLLM Proxy
echo "Starting LiteLLM Proxy..."
exec litellm --config /app/config.yaml --port 4000 --host 0.0.0.0