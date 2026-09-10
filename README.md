# Stable — release channel

Stable adds model selection, native harness switching, and independent review
to Claude Code, Codex, Pi, Prime and Jcode. Model requests use covering
subscriptions where available and the Conifer gateway otherwise. Launch
`stable cc`, `stable codex`, `stable pi`, `stable prime`, or `stable jcode` for
that harness's full native terminal interface.

`/harness NAME` closes the current Stable-owned native CLI and opens the selected
CLI in the same terminal and working directory. The active CLI owns its display,
streaming, tools, agents, permissions and interrupts. Stable does not render
another harness's output inside the previous host.

Each switch creates a fresh native conversation with bounded prior context.
Claude Code and Codex attach it to the first ordinary prompt; Pi/Prime load a
hidden native message, and Jcode imports a private native session. Switching
does not submit a preparatory model turn or replay old tools. Original native
transcripts remain available through each CLI's explicit resume controls.
Select a harness by name to switch back; `/harness off` and `/harness new` are
retired.

Switches use the same Stable setup as direct launches, preserving the provider
and model together. Prime's built-in model names cannot take over a Stable
subscription or gateway selection. Fresh Claude sessions can switch before
their transcript is created. Leaving a Claude subscription model for another
harness prefers an available Codex subscription's advertised default model
before routing Claude through the gateway. The admitted substitution is
announced; unusable defaults retain existing destination resolution. Ordinary
model selection and same-model quota fallback are unchanged. Delivered Claude/Codex context is retained for
later resumes and onward switches; a native clear discards it. If an older
release did not save that imported context, Stable keeps the source session
open and explains how to recover instead of silently losing it.

Hermes and OpenCode are documented adapters and refuse execution until their
integration is verified. Jcode switches through the launch-scoped
`harness_control` MCP tool. Its native custom slash-command discovery has no
private launch scope, so Stable does not install a global `/harness` skill.
In Jcode, say "Switch this terminal to Claude Code" (or another harness).
Its native parser does not accept `/harness`; the startup hint and chooser show
the supported MCP path. Imported sessions remain interactive.

This repository holds **only the compiled app and its installer**. The source
is private.

## Install (macOS, Apple Silicon)

```sh
curl -fsSL https://raw.githubusercontent.com/yinan4099/stable-release/main/install.sh | bash
```

The installer downloads the latest release, verifies its SHA-256, unpacks the
app under `~/.stable/releases/release.*/app` and links `~/.local/bin/stable`. The app carries its
own interpreter; each harness you use still needs its native CLI. It never
uses `sudo`. Upgrades publish a new app directory without changing or removing
previous runtimes. Curl and `stable update` both work alongside active sessions
and reviews; new sessions use the update while existing sessions keep running.
Installation does not restart shared services. Previous app directories remain
until uninstall so late imports and hook paths stay valid.
Upgrades refresh already installed Stable skills and extensions; they do not
enable integrations for new hosts. Restart an open host session to load them.

Then:

```sh
stable codex            # reuse your existing Codex ChatGPT login
stable status --subscriptions  # repeat the installer's subscription check
```

The installer detects an existing Codex subscription without displaying token
values or asking for a Gateway key. Detection also checks the native Codex CLI
inside Codex.app and ChatGPT.app in `~/Applications` or `/Applications` when
it is absent from PATH. `stable codex` loads Stable's private plugin for that
launch. Stable obtains Codex's native trust hashes for its exact verified hooks
and applies them only to that launch, avoiding repeated prompts after switching.
Foreign hooks keep their normal trust requirements, explicitly disabled hooks
remain disabled, and native configuration is unchanged. Covered Codex models can
use that subscription in every supported harness. If you are signed out, run
`stable codex login`. Signing in after installation needs no reinstall: bare
`stable` and commands that need model access check the current login again.
API keys do not count as subscriptions. A desktop app must expose a native
Codex ChatGPT login; being signed into a browser alone is insufficient.

`stable login` optionally adds a Conifer Gateway key for other models
([get a key](https://conifer.build/console#/keys)). For Claude Code, run
`stable install claude-code`, then `stable cc`. `stable doctor` checks the
installed dependencies and login readiness.

Stable adds only `/model`, `/harness`, and `/reviewer`; native commands such as
`/context` remain available. Codex's native skill picker shows `$stable:harness`
and `$stable:reviewer`; `$harness ENGINE` and `$reviewer astra|fable|off` remain
short aliases when no user skill owns the name. Its TUI rejects custom slash
names before hooks run. Existing user skills keep their names; `stable: /harness ...`
and `stable: /reviewer ...` remain available on a name collision.

Stable controls load only when launched with `stable`. Plain `claude` and
`codex` do not discover them. Updates remove old, unmodified Stable commands
from global skill folders while preserving edited files and unrelated skills.
Codex owns the bare `/model` command. In Pi and Prime, the default scoped `/model` rows
show `codex-subscription` or `conifer-gateway`. Stable preserves the harness
when changing models. Each CLI may perform its own first-use tool setup;
Prime also needs its Python kernel runtime and `uv` for native bootstrap.

The reviewer is active by default: Claude/Fable reviews Codex authors;
Codex/Astra reviews Claude Code, Pi, Prime, Jcode and terminal authors.
`stable reviewer off` disables future review outside Conifer projects. Paths
under `~/Desktop/Conifer`, their linked worktrees and repositories with a
ConiferKit GitHub remote require review; off refuses there. Settings are local
and do not start reviews or probe accounts. `/reviewer astra` selects a separate native
Codex reviewer; `/reviewer fable` selects Claude Code. Explicit choices survive
resume and harness switching. In Codex, use `$stable:reviewer` or an unclaimed
`$reviewer` alias; Jcode uses `/Reviewer` with a capital R.

With verified Claude Code 2.1.263 or newer, bare `/reviewer` and `/harness` open
native selection dialogs before any model call. Cancellation preserves settings;
explicit commands still work if MCP is disconnected. Older versions retain local
text controls. Codex's skill controls require an author tool-call turn, while
its built-in `/model` picker opens immediately.

When Claude uses a Codex-subscription model, Stable preserves native hook
context as supported developer input. This keeps transferred conversation in
the actual model request across first prompts, later prompts and resume;
clearing the conversation removes it.

For code changes or an explicitly requested source review, the author completes
implementation, validation and self-review, then calls
`review_changes` once. Review runs at medium effort with a two-minute ceiling and
returns a two-sentence preview in a complete five-line box. Full findings and
checks stay in the saved report, accessible with the preview’s
`stable reviewer result ID --json` command. Read it before acting on findings or
a limited/failed review. Codex controls whether the outer tool call is expanded;
Stable does not force it to collapse. The author checks applicability,
fixes valid issues, and validates before its final response. No background review,
wait/ack loop, delayed continuation, deep mode or capability profiles are used.
The caller owns cancellation. A missing native subscription may fall back to the
other native reviewer once within the same deadline; results name the actual
reviewer, and no gateway or paid API route is substituted.

Ordinary questions, arithmetic, conversation and settings changes need no review.
An explicit empty file list returns “Not needed” locally without starting a
reviewer, searching the workspace or building a graph.
Selecting a reviewer does not itself start one. Reviewer status distinguishes
the current task's review from older saved results and reports when no review
is recorded for the current task.

Graphify is the only extra MCP. It uses a private pinned
`graphifyy[mcp,sql]==0.9.55` runtime with Python 3.10–3.13. Run
`stable reviewer setup` to install it or `stable reviewer setup --status` to
inspect readiness. Existing owned runtimes are reused. Queries build local
code-only indexes lazily and validate content/version/lock freshness before reuse.
Corrupt indexes are rebuilt; source changes and static-analysis gaps are explicit.
No user MCP configuration or global Graphify hooks are changed.

The author can call `graph_query` directly even while review is off, or use
`stable reviewer graph --cwd PROJECT --query TEXT`. It needs no reviewer job or
model inference. The reviewer retains native files and shell checks; inherited
MCPs/plugins are disabled only for its child process. The source checkout's `docs/reviewer.md` describes input, report and scope details.

`stable default` optionally routes interactive native commands through Stable.
Fresh installs leave this off. Run the printed activation command in the same terminal;
`stable default off` reverses it, and `stable native HARNESS ...` runs the
original native CLI. Utility commands and headless native protocols retain
their original behavior.

Model discovery remains dynamic. `stable model check --all` measures text,
streaming, a read-only tool round trip and completion on available routes.
Confirmed failures are excluded for the affected route; network, login,
rate-limit and server problems remain retryable. Use `stable model excluded`
to inspect, `stable model retry ID` to recheck, and `stable model include ID`
to remove a manual exclusion. New models appear automatically.

Every normal launch of an installed release requests a background update check;
concurrent launches coalesce without waiting for the network. Long sessions check
every 12 hours while Stable stays active. Automatic updates use the same verified
installer and publish for new sessions without stopping active work.
`stable update` downloads and verifies the release and waits for installation;
it can run from an active session. Unverified installation ownership refuses
publication. `stable update check` only checks, and
`stable update status` shows local progress. Set `STABLE_AUTO_UPDATE=0` or
`"auto_update": false` in `~/.stable/config.json` to disable automatic updates.
Source checkouts and developer builds do not update automatically.

Anonymous installation and usage reporting is on by default. Stable reports a
random installation ID, version/platform, harness/model, payment lane, and
available token counts and cost estimates. It never reports prompts, responses,
file paths, credentials or account emails. Updates preserve the installation ID.
`stable analytics status` shows local reporting state; `stable analytics off`
disables reporting and clears pending uploads. `stable analytics on` enables it
again. `STABLE_ANONYMOUS_USAGE=0` also disables reporting for that invocation.
Uploads are bounded and run in the background; failures do not block inference.

Stable's private dataroom section keeps these counters separate from Conifer
billing and other product analytics. Active installations approximate users;
they cannot identify a person across devices. Subscription tokens and their
estimated API-equivalent value are separate from API-key usage and spend.
Missing usage or price data stays unknown, and subscription estimates are never
treated as an actual subscription bill.

Manual update: run `stable update`. `stable uninstall --dry-run`
previews removal; `stable uninstall` removes Stable and its owned integrations.
Native CLIs and logins remain, and history is retained by default. Add
`--purge-data` during uninstall to remove recorded Stable data. Active Stable
work must finish or be cancelled before uninstall. `stable uninstall HOST`
removes only that host integration; it is separate from `stable default off`.

## Releases

Every release ships `stable-macos-arm64.tar.gz` and its `.sha256`. The version
is `0.1.<build>+<commit>`.
