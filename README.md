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
stable login            # paste a Conifer Gateway key (https://conifer.build/console#/keys)
stable install claude-code  # wire the Claude Code integration
stable doctor           # one line per dependency
stable cc               # Claude Code on Stable's lanes (also: stable codex, stable pi)
```

Update: run the same `curl … | bash` line again. Remove each integration with
`stable uninstall HOST` (for example, `stable uninstall claude-code`), stop
Stable's services with `stable proxy stop` and `stable broker stop`, then
delete `~/.stable` and `~/.local/bin/stable`.

## Releases

Every release ships `stable-macos-arm64.tar.gz` and its `.sha256`. The version
is `0.1.<build>+<commit>`.
