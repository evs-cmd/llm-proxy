.PHONY: build up down restart rebuild logs logs-file health test models

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose down && docker compose up -d

rebuild:
	docker compose down && docker compose up --build -d

logs:
	docker compose logs -f

logs-file:
	tail -f logs/litellm.log

health:
	curl -s http://localhost:4000/health | python3 -m json.tool

models:
	curl -s http://localhost:4000/v1/models \
		-H "Authorization: Bearer $$(grep LITELLM_MASTER_KEY .env | cut -d= -f2)" | python3 -m json.tool

test:
	curl -s http://localhost:4000/v1/messages \
		-H "Authorization: Bearer $$(grep LITELLM_MASTER_KEY .env | cut -d= -f2)" \
		-H "Content-Type: application/json" \
		-H "anthropic-version: 2023-06-01" \
		-d '{"model": "claude-sonnet-4-6", "max_tokens": 50, "messages": [{"role": "user", "content": "hi"}]}' | python3 -m json.tool
