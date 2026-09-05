# Stable — release channel

Stable adds model selection, harness switching, Ask and external subagents to
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
Upgrades refresh already installed Stable skills and extensions; they do not
enable integrations for new hosts. Restart an open host session to load them.

Then:

```sh
stable codex            # reuse your existing Codex ChatGPT login
stable status --subscriptions  # repeat the installer's subscription check
```

The installer detects an existing Codex subscription without displaying token
values or asking for a Gateway key. `stable codex` wires Stable's marked hook
if needed; trust it once with `/hooks` in Codex. Covered Codex models can use
that subscription in every supported harness. If you are signed out, run
`codex login`. API keys do not count as subscriptions.

`stable login` optionally adds a Conifer Gateway key for other models
([get a key](https://conifer.build/console#/keys)). For Claude Code, run
`stable install claude-code`, then `stable cc`. `stable doctor` checks the
installed dependencies and login readiness.

Inside Codex, use `stable: /harness ENGINE` and `stable: /ask ENGINE PROMPT`;
Codex owns the bare `/model` command. In Pi and Prime, the default scoped `/model` rows
show `codex-subscription` or `conifer-gateway`. Stable preserves the harness
when changing models. Each CLI may perform its own first-use tool setup;
Prime also needs its Python kernel runtime and `uv` for native bootstrap.

Update: run the same `curl … | bash` line again. Remove each integration with
`stable uninstall HOST` (for example, `stable uninstall claude-code`), stop
Stable's services with `stable proxy stop` and `stable broker stop`, then
delete `~/.stable` and `~/.local/bin/stable`.

## Releases

Every release ships `stable-macos-arm64.tar.gz` and its `.sha256`. The version
is `0.1.<build>+<commit>`.
