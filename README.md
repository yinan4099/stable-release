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

Hermes and OpenCode are documented adapters and refuse execution until their
integration is verified. Jcode switches through the launch-scoped
`harness_control` MCP tool. Its native custom slash-command discovery has no
private launch scope, so Stable does not install a global `/harness` skill.

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
The curl installer preserves active work and refuses replacement while current
Stable launches or reviews are active. `stable update` explicitly stops verified
Stable work after staging and checking the release, then waits for installation.
Run it from a separate terminal and restart host sessions afterward.
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
launch; Codex may ask you to review and trust its three hooks once. Covered Codex models can use
that subscription in every supported harness. If you are signed out, run
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

The reviewer is off by default. `/reviewer astra` selects a separate native
Codex reviewer; `/reviewer fable` selects Claude Code. Explicit choices survive
resume and harness switching. In Codex, use `$stable:reviewer` or an unclaimed
`$reviewer` alias; Jcode uses `/Reviewer` with a capital R.

After implementation, validation and self-review, the author calls
`review_changes` once. Review runs at medium effort with a two-minute ceiling and
returns a concise report in that same call. The author checks applicability,
fixes valid issues, and validates before its final response. No background review,
wait/ack loop, delayed continuation, deep mode or capability profiles are used.
The caller owns cancellation. A missing native subscription may fall back to the
other native reviewer once within the same deadline; results name the actual
reviewer, and no gateway or paid API route is substituted.

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

Every normal launch of an installed release requests a background update check;
concurrent launches coalesce without waiting for the network. Long sessions check
every 12 hours while Stable stays active. Automatic updates use the same verified
installer and wait for active Stable sessions and reviews to finish.
`stable update` downloads and verifies the release, stops owned Stable work with
bounded escalation, and waits for installation. Unverified ownership refuses
replacement. `stable update check` only checks, and
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

Manual update: run `stable update` from a separate terminal. `stable uninstall --dry-run`
previews removal; `stable uninstall` removes Stable and its owned integrations.
Native CLIs and logins remain, and history is retained by default. Add
`--purge-data` during uninstall to remove recorded Stable data. Active Stable
work must finish or be cancelled before uninstall. `stable uninstall HOST`
removes only that host integration; it is separate from `stable default off`.

## Releases

Every release ships `stable-macos-arm64.tar.gz` and its `.sha256`. The version
is `0.1.<build>+<commit>`.
