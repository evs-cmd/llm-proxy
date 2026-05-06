# Use a glibc-based slim image for better compatibility with Python C-extensions
FROM python:3.11-slim

# Install system dependencies & Tailscale
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    iptables \
    libatomic1 \
    && curl -fsSL https://tailscale.com/install.sh | sh \
    && rm -rf /var/lib/apt/lists/*

# Install LiteLLM + prisma (needed for auth handler even without a DB)
RUN pip install --no-cache-dir 'litellm[proxy]==1.83.14' prisma

WORKDIR /app

# We use a script to handle the dual-boot of Tailscale + LiteLLM
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose LiteLLM port
EXPOSE 4000

ENTRYPOINT ["/entrypoint.sh"]