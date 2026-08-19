# AGENTS.md

## Overview

NexCLI is a single-package TypeScript coding agent for the NexLM family of LLMs. It is maintained by Arsis Technologys. There are no databases, Docker services, or extra daemons required for local development. See `README.md` for user documentation.

## Commands

```bash
bun install
bun run dev
bun run build
bun run start
bun run typecheck
bun run lint
bun run test
```

Use `bun run typecheck` as the primary code quality check. The CLI binary name is `nex`.

## Environment

| Variable | Required | Description |
| --- | --- | --- |
| `NEX_API_KEY` | Yes | API key for NexLM |
| `NEX_BASE_URL` | No | Custom API endpoint |
| `NEX_MODEL` | No | Model override |
| `NEX_MAX_TOKENS` | No | Max tokens per response (default: 16384) |
| `TELEGRAM_BOT_TOKEN` | No | Telegram remote control |

User settings live in `~/.nex/user-settings.json`. Project settings live in `.nex/settings.json`.

## Platform notes

- Installer support: `darwin-arm64`, `darwin-x64`, `linux-x64`, `linux-arm64`, `windows-x64`.
- Bun currently requires macOS 13.0 or later.
- Sandbox and computer-use features require Apple Silicon and macOS 14+.
- Intel Macs can install via the script, then run from a source build when no `darwin-x64` release binary exists.

## Branding

Use **NexCLI** for the product, **nex** for the command, and **NexLM** for the model family. Do not refer to this project as Grok CLI.
