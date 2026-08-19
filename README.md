# NexCLI: a coding agent for the NexLM family

A terminal coding agent for the **NexLM** family of LLMs from **Arsis Technologys** — web search, sub-agents on by default, remote control via Telegram, and a terminal UI built with **Bun** and **OpenTUI**.

> NexCLI is the command-line interface for NexLM. It is not affiliated with xAI or Grok.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/besmart12349/NexCLI/main/install.sh | bash
```

**Alternative installs** (requires Bun on PATH):

```bash
bun add -g nexcli
```

**Self-management** (script-installed only):

```bash
nex update
nex uninstall
nex uninstall --dry-run
nex uninstall --keep-config
```

**Prerequisites:** a **NexLM API key** and a modern terminal emulator for the interactive OpenTUI experience. Headless `--prompt` mode does not depend on terminal UI support. If you want host desktop automation via the built-in computer sub-agent, also enable **Accessibility** permission for your terminal app on macOS.

## Run it

**Interactive (default)** — launches the OpenTUI coding agent:

```bash
nex
```

### Supported terminals

For the most reliable interactive OpenTUI experience, use a modern terminal emulator. We currently document and recommend:

- **WezTerm** (cross-platform)
- **Alacritty** (cross-platform)
- **Ghostty** (macOS and Linux)
- **Kitty** (macOS and Linux)

Other modern terminals may work, but these are the terminal apps we currently recommend and document for interactive use.

**Pick a project directory:**

```bash
nex -d /path/to/your/repo
```

**Headless** — one prompt, then exit (scripts, CI, automation):

```bash
nex --prompt "run the test suite and summarize failures"
nex -p "show me package.json" --directory /path/to/project
nex --prompt "refactor X" --max-tool-rounds 30
nex --prompt "summarize the repo state" --format json
nex --prompt "review the repo overnight" --batch-api
nex --verify
```

`--batch-api` is a good fit for scripts, CI, schedules, and other non-interactive workflows where a delayed result is fine.

**Continue a saved session:**

```bash
nex --session latest
nex -s <session-id>
```

Works in interactive mode too — same flag.

**Structured headless output:**

```bash
nex --prompt "summarize the repo state" --format json
```

`--format json` emits a newline-delimited JSON event stream instead of the default human-readable text output. Events are semantic, step-level records such as `step_start`, `text`, `tool_use`, `step_finish`, and `error`.

### Computer sub-agent

NexCLI ships a built-in **computer** sub-agent backed by [agent-desktop](https://github.com/lahfir/agent-desktop) for host desktop automation on macOS.

Ask for it in natural language, for example:

```bash
nex "Use the computer sub-agent to take a screenshot of my host desktop and tell me what is open."
nex "Use the computer sub-agent to launch Google Chrome, snapshot the UI, and tell me which refs correspond to the address bar and tabs."
```

Notes:

- Screenshots are saved under `.nex/computer/` by default.
- The primary workflow is **snapshot -> refs -> action -> snapshot** using `agent-desktop` accessibility snapshots and stable refs like `@e1`.
- `computer_screenshot` is available for visual confirmation, but the preferred path is `computer_snapshot` plus ref-based actions such as `computer_click`, `computer_type`, and `computer_scroll`.
- macOS requires **System Settings → Privacy & Security → Accessibility** access for the terminal app running `nex`.
- `agent-desktop` currently targets **macOS**.
- If Bun blocks the native binary download during install, run:

```bash
node ./node_modules/agent-desktop/scripts/postinstall.js
```

### Scheduling

Schedules let NexCLI run a headless prompt on a recurring schedule or once. Ask for it in natural language, for example:

```text
Create a schedule named daily-changelog-update that runs every weekday at 9am
and updates CHANGELOG.md from the latest merged commits.
```

Recurring schedules require the background daemon:

```bash
nex daemon --background
```

Use `/schedule` in the TUI to browse saved schedules. One-time schedules start immediately in the background; recurring schedules keep running as long as the daemon is active.

**List NexLM models:**

```bash
nex models
```

**Pass an opening message without another prompt:**

```bash
nex fix the flaky test in src/foo.test.ts
```

**Generate images or short videos from chat:**

```bash
nex "Generate a retro-futuristic logo for my CLI called NexCLI"
nex "Edit ./assets/hero.png into a watercolor poster"
nex "Animate ./assets/cover.jpg into a 6 second cinematic push-in"
```

Image and video generation are exposed as agent tools inside normal chat sessions. You keep using a text model for the session, and NexCLI saves generated media under `.nex/generated-media/` by default unless you ask for a specific output path.

## What you actually get

| Thing | What it means |
| --- | --- |
| **Built for NexLM** | Defaults tuned for the NexLM family of models. Run `nex models` for the full menu. |
| **Web search** | Live docs and pages without pretending the internet stopped in 2023. |
| **Media generation** | Built-in `generate_image` and `generate_video` tools for text-to-image, image editing, text-to-video, and image-to-video flows. Generated files are saved locally. |
| **Sub-agents (default)** | Foreground `task` delegation (explore, general, or computer) plus background `delegate` for read-only deep dives. |
| **Verify** | `/verify` or `--verify` — inspects your app, builds, tests, boots it, and runs browser smoke checks in a sandboxed environment. |
| **Computer use** | Built-in `computer` sub-agent for host desktop automation via `agent-desktop`. Screenshots save under `.nex/computer/` when requested. |
| **Custom sub-agents** | Define named agents with `subAgents` in `~/.nex/user-settings.json` and manage them from the TUI with `/agents`. |
| **Remote control** | Pair Telegram from the TUI (`/remote-control` → Telegram): DM your bot, `/pair`, approve the code in-terminal. |
| **OpenTUI** | Fast, keyboard-driven React terminal UI built with Bun and OpenTUI. |
| **Skills** | Agent Skills under `.agents/skills/<name>/SKILL.md` (project) or `~/.agents/skills/` (user). Use `/skills` in the TUI. |
| **MCPs** | Extend with Model Context Protocol servers via `/mcps` in the TUI or `.nex/settings.json` (`mcpServers`). |
| **Sessions** | Conversations persist; `--session latest` picks up where you left off. |
| **Headless** | `--prompt` / `-p` for non-interactive runs — pipe it, script it, bench it. |
| **Hackable** | TypeScript, clear agent loop, bash-first tools — fork it. |

### Coming soon

**Deeper autonomous agent testing** — persistent sandbox sessions, richer browser workflows, and stronger "prove it works" evidence.

## API key (pick one)

**Environment (good for CI):**

```bash
export NEX_API_KEY=your_key_here
```

`.env` in the project (see `.env.example` if present):

```bash
NEX_API_KEY=your_key_here
```

**CLI once:**

```bash
nex -k your_key_here
```

**Saved in user settings** — `~/.nex/user-settings.json`:

```json
{ "apiKey": "your_key_here" }
```

Optional `subAgents` — custom foreground sub-agents. Each entry needs `name`, `model`, and `instruction`:

```json
{
  "subAgents": [
    {
      "name": "security-review",
      "model": "nexlm",
      "instruction": "Prioritize security implications and suggest concrete fixes."
    }
  ]
}
```

Names cannot be `general`, `explore`, `vision`, `verify`, or `computer` because those are reserved for the built-in sub-agents.

Optional: `NEX_BASE_URL`, `NEX_MODEL`, `NEX_MAX_TOKENS`.

## Telegram (remote control) — short version

1. Create a bot with [@BotFather](https://t.me/BotFather), copy the token.
2. Set `TELEGRAM_BOT_TOKEN` or add `telegram.botToken` in `~/.nex/user-settings.json` (the TUI `/remote-control` flow can save it).
3. Start `nex`, open `/remote-control` → **Telegram** if needed, then in Telegram DM your bot: `/pair`, enter the **6-character code** in the terminal when asked.
4. First user must be approved once; after that, it’s remembered. **Keep the CLI process running** while you use the bot (long polling lives in that process).

### Voice & audio messages

Send a voice note or audio attachment in Telegram and NexCLI will transcribe it before passing the text to the agent. The endpoint accepts Telegram's OGG/Opus voice notes and common audio containers (MP3, WAV, M4A, FLAC, AAC).

#### Configure in ~/.nex/user-settings.json

```json
{
  "telegram": {
    "botToken": "YOUR_BOT_TOKEN",
    "audioInput": {
      "enabled": true,
      "language": "en"
    }
  }
}
```

| Setting | Default | Description |
| --- | --- | --- |
| `enabled` | `true` | Set to `false` to ignore voice/audio messages entirely. |
| `language` | `en` | Language code forwarded to speech-to-text. |

Optional headless flow when you do not want the TUI open:

```bash
nex telegram-bridge
```

Treat the bot token like a password.

## Hooks

Hooks execute shell commands at key agent lifecycle events — enforce policies, run linters, trigger tests, or log activity.

Configure in `~/.nex/user-settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "bash",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/lint-before-edit.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Hook commands receive JSON on **stdin** (event details) and can return JSON on **stdout**. Exit code `0` = success, `2` = block the action, other = non-blocking error.

**Supported events:** `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `UserPromptSubmit`, `SessionStart`, `SessionEnd`, `Stop`, `StopFailure`, `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `PreCompact`, `PostCompact`, `Notification`, `InstructionsLoaded`, `CwdChanged`.

## Instructions & project brain

- `AGENTS.md` — merged from git root down to your cwd. `AGENTS.override.md` wins per directory when present.

## Project settings

Project file: `.nex/settings.json` — e.g. the current model for this project.

## Sandbox

NexCLI can run shell commands inside a Shuru microVM sandbox so the agent can't touch your host filesystem or network.

**Requires macOS 14+ on Apple Silicon.**

Enable it with `--sandbox` on the CLI, or toggle it from the TUI with `/sandbox`.

On the first interactive run in a new directory, NexCLI asks whether to remember sandbox or host mode for that workspace and stores the choice in `~/.nex/workspace-trust.json`. Explicit `--sandbox` / `--no-sandbox` flags and non-interactive commands keep their current behavior.

When sandbox mode is active you can configure:

- **Network** — off by default; enable with `--allow-net`, restrict with `--allow-host`
- **Port forwards** — `--port 8080:80`
- **Resource limits** — CPUs, memory, disk size (via settings or `/sandbox` panel)
- **Checkpoints** — start from a saved environment snapshot
- **Secrets** — inject API keys without exposing them inside the VM

All settings are saved in `~/.nex/user-settings.json` (user) and `.nex/settings.json` (project).

### Verify

Run `/verify` in the TUI or `--verify` on the CLI to verify your app locally:

```bash
nex --verify
nex -d /path/to/your/app --verify
```

The agent inspects your project, figures out how to build and run it, spins up a sandbox, and produces a verification report with screenshots and video evidence. Works with any app type.

## Troubleshooting

### Installation issues

**Install script fails on macOS**

```bash
which curl
bash -c "$(curl -fsSL https://raw.githubusercontent.com/besmart12349/NexCLI/main/install.sh)"
```

**Bun not found**

```bash
curl -fsSL https://bun.sh/install | bash
bun add -g nexcli
```

### API key issues

**"Missing NEX_API_KEY" error**

```bash
export NEX_API_KEY=your_key_here
nex -k your_key_here
```

### Terminal UI issues

**UI doesn't render correctly**

Try WezTerm, Alacritty, Ghostty, or Kitty.

**Screen flickering or artifacts**

Ensure your terminal supports true color and Unicode. Update your terminal emulator to the latest version.

### Telegram remote control

**Bot doesn't respond**

1. Verify `TELEGRAM_BOT_TOKEN` is set correctly
2. Ensure the CLI process is still running
3. Check that you've completed the `/pair` flow and been approved

**Voice messages not transcribing**

- Verify `NEX_API_KEY` is set
- Check `~/.nex/user-settings.json` has `telegram.audioInput.enabled: true`

### Sandbox mode

**Sandbox only works on macOS 14+ with Apple Silicon**

If you're on Intel Mac or Linux, sandbox mode is not available. Use standard mode without `--sandbox`.

### Performance issues

**Slow response times**

- Check your network connection to the NexLM API
- Reduce `--max-tool-rounds` for headless runs

**High memory usage**

- Long-running sessions accumulate context; start a fresh session periodically
- Use `/compact` in TUI to compress conversation history

### Getting help

- Check existing issues
- Open a new issue with:
  - OS and terminal emulator version
  - NexCLI version (`nex --version`)
  - Steps to reproduce
  - Error messages or logs

## Development

From a clone:

```bash
bun install
bun run build
bun run start
# or: node dist/index.js
```

Other useful commands:

```bash
bun run dev        # run from source (Bun)
bun run typecheck
bun run lint
```

## Credits

NexCLI is maintained by [Arsis Technologys](https://github.com/besmart12349). The agent architecture is adapted from the MIT-licensed [superagent-ai/grok-cli](https://github.com/superagent-ai/grok-cli) project.

## License

MIT
