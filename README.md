# Stable — release channel

Stable is the reliability-first, no-UI control plane for coding-agent
harnesses: one `stable` command, driven entirely through slash commands inside
Claude Code, Codex, pi, Hermes, prime-agent and jcode. It routes models to the
Conifer Gateway, keeps your Claude and Codex subscriptions in play where they
apply, and lets one harness execute prompts for another with the conversation
carried across.

This repository holds **only the compiled app and its installer**. The source
is private.

## Install (macOS, Apple Silicon)

```sh
curl -fsSL https://raw.githubusercontent.com/yinan4099/stable-release/main/install.sh | bash
```

The installer downloads the latest release, verifies its SHA-256, unpacks the
app under `~/.stable/app` and links `~/.local/bin/stable`. The app carries its
own interpreter; nothing else is required. It never uses `sudo`.

Then:

```sh
stable login            # paste a Conifer Gateway key (https://conifer.build/console#/keys)
stable install          # wire /model, /harness, /ask into the harnesses on this Mac
stable doctor           # one line per dependency
stable cc               # Claude Code on Stable's lanes (also: stable codex, stable pi)
```

Update: run the same `curl … | bash` line again. Remove: `stable uninstall`,
then delete `~/.stable` and `~/.local/bin/stable`.

## Releases

Every release ships `stable-macos-arm64.tar.gz` and its `.sha256`. The version
is `0.1.<build>+<commit>`.
