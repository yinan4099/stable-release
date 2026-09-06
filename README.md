# Stable — release channel

Stable adds model selection, harness switching, Ask, external subagents and independent review to
coding CLIs. Claude Code is the reference host; execution adapters also drive
Codex, pi, prime-agent and jcode. Model requests use covering subscriptions
where available and the Conifer gateway otherwise. Harness switches carry
the visible conversation across.

Hermes and OpenCode are documented adapters and refuse execution until their
integration is verified. jcode supports streaming Ask and engine execution;
it has no host prompt hook for persistent harness switching.

This repository holds **only the compiled app and its installer**. The source
is private.

## Install (macOS, Apple Silicon)

```sh
curl -fsSL https://raw.githubusercontent.com/yinan4099/stable-release/main/install.sh | bash
```

The installer downloads the latest release, verifies its SHA-256, unpacks the
app under `~/.stable/app` and links `~/.local/bin/stable`. The app carries its
own interpreter; each harness you use still needs its native CLI. It never
uses `sudo`. Upgrades stage the replacement before swapping the app, and
retain the previous files when an owned service cannot be restarted.
Updates refuse while current Stable launches or reviews are active; finish or
cancel that work before retrying. Older sessions that predate this guard keep
their previous app files and continue running. Restart host sessions after an
upgrade to load the new hooks and tools.
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
it is absent from PATH. `stable codex` wires Stable's marked hook
if needed; trust it once with `/hooks` in Codex. Covered Codex models can use
that subscription in every supported harness. If you are signed out, run
`stable codex login`. Signing in after installation needs no reinstall: bare
`stable` and commands that need model access check the current login again.
API keys do not count as subscriptions. A desktop app must expose a native
Codex ChatGPT login; being signed into a browser alone is insufficient.

`stable login` optionally adds a Conifer Gateway key for other models
([get a key](https://conifer.build/console#/keys)). For Claude Code, run
`stable install claude-code`, then `stable cc`. `stable doctor` checks the
installed dependencies and login readiness.

Inside Codex, use `stable: /harness ENGINE` and `stable: /ask ENGINE PROMPT`;
Codex owns the bare `/model` command. In Pi and Prime, the default scoped `/model` rows
show `codex-subscription` or `conifer-gateway`. Stable preserves the harness
when changing models. Each CLI may perform its own first-use tool setup;
Prime also needs its Python kernel runtime and `uv` for native bootstrap.

New sessions start with review off. `/reviewer astra` selects a separate
native Codex reviewer using the machine's ChatGPT subscription;
`/reviewer fable` selects native Claude Code using its own subscription.
Review supplements completed implementation, validation, and author self-review.
Automatic review runs in the background once per task in Claude Code, Codex, Pi
and Prime. Standard reviews use high effort; `/reviewer deep` requests the model's
supported higher effort with a 30-minute deadline. Material findings appear in a
bounded review box; automatic clean results stay quiet. Results remain on disk
until acknowledged, and the author can keep working while a deep review runs.
`/reviewer manual` keeps on-demand access, and `/reviewer off` disables future
reviews. Use `stable reviewer cancel JOB` for an active job. In Codex, spell
these commands `stable: /reviewer astra` or `stable: /reviewer off`. Jcode supports
on-demand review inside `stable jcode`. The same service is available to other
MCP clients with `stable reviewer mcp --host H --session S --cwd C`.

Setup prepares free reviewer tools privately under `~/.stable/reviewer`, without
adding them to the normal harness or changing independently configured copies.
`stable reviewer setup --status` reports prerequisites and readiness. Local tools
require Node/npm, Python 3.10–3.13 for code graphs, and Chrome for browser checks.
The reviewer can inspect an immutable source capture and run tests in disposable
OS sandboxes; a missing or failing sandbox disables execution. Browser checks are
currently verified on macOS and restricted to review-owned local fixtures.
Graph indexes, public npm lockfile dependencies, and schemas use bounded private
caches; fresh review verdicts are never replaced by cached approvals.

`stable default` optionally routes interactive native commands through Stable.
Fresh installs leave this off. Open a new terminal after enabling it;
`stable default off` reverses it, and `stable native HARNESS ...` runs the
original native CLI. Utility commands and headless native protocols retain
their original behavior.

Model discovery remains dynamic. `stable model check --all` measures text,
streaming, a read-only tool round trip and completion on available routes.
Confirmed failures are excluded for the affected route; network, login,
rate-limit and server problems remain retryable. Use `stable model excluded`
to inspect, `stable model retry ID` to recheck, and `stable model include ID`
to remove a manual exclusion. New models appear automatically.

Update: run the same `curl … | bash` line again. `stable uninstall --dry-run`
previews removal; `stable uninstall` removes Stable and its owned integrations.
Native CLIs and logins remain, and history is retained by default. Add
`--purge-data` during uninstall to remove recorded Stable data. Active Stable
work must finish or be cancelled before uninstall. `stable uninstall HOST`
removes only that host integration; it is separate from `stable default off`.

## Releases

Every release ships `stable-macos-arm64.tar.gz` and its `.sha256`. The version
is `0.1.<build>+<commit>`.
