#!/bin/sh
# Stable — one-line installer (macOS, Apple Silicon).
#
#   curl -fsSL https://raw.githubusercontent.com/yinan4099/stable-release/main/install.sh | bash
#
# Downloads the latest published stable-macos-arm64.tar.gz from the release
# channel, verifies it against the release's own sha256 asset, unpacks it under
# ~/.stable/app and links ~/.local/bin/stable to it. The app carries its own
# Python interpreter, so nothing else is required. Fails CLOSED at every step:
# nothing changes unless the download completed AND the hash matched. No sudo,
# ever — everything lands under $HOME. View this plain file before running it.
#
# The Conifer CLI is installed too when it is missing (Stable's `stable cc`
# needs it to serve gateway models) — from the public ConiferKit/CLI-release
# channel, through its own verified installer. Set STABLE_SKIP_CONIFER=1 to skip.
#
#   STABLE_INSTALL_VERSION=v0.1.123+abc1234   install a specific release
set -eu

REPO="${STABLE_RELEASE_REPO:-yinan4099/stable-release}"
ASSET="stable-macos-arm64.tar.gz"
APP_HOME="${STABLE_HOME:-$HOME/.stable}"
BIN_DIR="$HOME/.local/bin"

[ "$(uname -s)" = "Darwin" ] || { echo "  ✗ Stable's app build is macOS-only." >&2; exit 1; }
ARCH="$(uname -m)"
if [ "$ARCH" = "x86_64" ] && [ "$(sysctl -in hw.optional.arm64 2>/dev/null)" = "1" ]; then ARCH=arm64; fi
[ "$ARCH" = "arm64" ] || { echo "  ✗ Stable's app build is Apple Silicon-only (found $ARCH)." >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "  ✗ curl is required." >&2; exit 1; }
command -v shasum >/dev/null 2>&1 || { echo "  ✗ shasum is required to verify the download." >&2; exit 1; }

WORK="$(mktemp -d /tmp/stable-install.XXXXXX)"
INSTALL_LOCK=""
cleanup() {
  rm -rf "$WORK"
  if [ -n "$INSTALL_LOCK" ]; then rmdir "$INSTALL_LOCK" 2>/dev/null || true; fi
}
trap cleanup EXIT

if [ -n "${STABLE_INSTALL_VERSION:-}" ]; then
  BASE="https://github.com/$REPO/releases/download/$STABLE_INSTALL_VERSION"
else
  BASE="https://github.com/$REPO/releases/latest/download"
fi

printf '\n  Installing Stable…\n\n'
echo "  → downloading the latest release"
if ! curl --proto '=https' --tlsv1.2 -fsSL -m 600 -o "$WORK/$ASSET" "$BASE/$ASSET" \
   || ! curl --proto '=https' --tlsv1.2 -fsSL -m 60 -o "$WORK/$ASSET.sha256" "$BASE/$ASSET.sha256"; then
  echo "  ✗ no Stable release could be downloaded from $REPO — nothing was installed." >&2
  exit 1
fi

# Fail CLOSED on a hash mismatch: a truncated or tampered download never reaches the install step.
EXPECT="$(awk 'NR==1{print $1}' "$WORK/$ASSET.sha256")"
GOT="$(shasum -a 256 "$WORK/$ASSET" | awk '{print $1}')"
if [ -z "$EXPECT" ] || [ "$GOT" != "$EXPECT" ]; then
  echo "  ✗ sha256 mismatch on the download — refusing it. Nothing was installed." >&2
  exit 1
fi
echo "  ✓ sha256 verified"

mkdir -p "$WORK/unpack"
tar -xzf "$WORK/$ASSET" -C "$WORK/unpack"
[ -x "$WORK/unpack/stable/stable" ] || { echo "  ✗ the archive has no stable/stable app inside — refusing it." >&2; exit 1; }
VERSION="$("$WORK/unpack/stable/stable" --version 2>/dev/null | awk '{print $2}')"
[ -n "$VERSION" ] || { echo "  ✗ the downloaded app does not run on this Mac — nothing was installed." >&2; exit 1; }

# Swap the app in atomically: unpack beside it, then rename. A running broker keeps its
# old files open until it restarts (`stable cc` restarts one that is Stable's own).
mkdir -p "$APP_HOME" "$BIN_DIR"
chmod 700 "$APP_HOME"
if ! mkdir "$APP_HOME/install.lock" 2>/dev/null; then
  echo "  ✗ another install is active (or was interrupted); inspect $APP_HOME/install.lock before retrying." >&2
  exit 1
fi
INSTALL_LOCK="$APP_HOME/install.lock"
rm -rf "$APP_HOME/app.new"
mv "$WORK/unpack/stable" "$APP_HOME/app.new"
BACKUP=""
if [ -d "$APP_HOME/app" ]; then
  BACKUP="$(mktemp -d "$APP_HOME/app.previous.XXXXXX")"
  mv "$APP_HOME/app" "$BACKUP/app"
fi
if ! mv "$APP_HOME/app.new" "$APP_HOME/app"; then
  if [ -n "$BACKUP" ]; then mv "$BACKUP/app" "$APP_HOME/app"; fi
  echo "  ✗ app swap failed; the previous installation was restored." >&2
  exit 1
fi
ln -sf "$APP_HOME/app/stable" "$BIN_DIR/stable"
echo "  ✓ stable $VERSION → $APP_HOME/app (linked at $BIN_DIR/stable)"

# A Palm broker Stable started runs from the OLD app's files: restart it on the new ones
# before those files go (live Claude Code sessions are registered again on their next prompt).
KEEP_BACKUP=0
if [ -f "$APP_HOME/broker.pid" ]; then
  if "$APP_HOME/app/stable" broker restart >/dev/null 2>&1; then
    echo "  ✓ Stable's Palm broker restarted on the new app"
  else
    KEEP_BACKUP=1
    echo "  ⚠ Stable's Palm broker could not be restarted — run: stable broker restart"
  fi
fi
if [ -f "$APP_HOME/proxy/proxy.pid" ]; then
  if "$APP_HOME/app/stable" proxy restart >/dev/null 2>&1; then
    echo "  ✓ Stable's proxy restarted on the new app"
  else
    KEEP_BACKUP=1
    echo "  ⚠ Stable's proxy could not be restarted — finish active sessions, then run: stable proxy restart"
  fi
fi
if "$APP_HOME/app/stable" install --refresh-installed >"$WORK/integration-refresh.log" 2>&1; then
  echo "  ✓ refreshed previously installed host integrations"
else
  KEEP_BACKUP=1
  cat "$WORK/integration-refresh.log" >&2
  echo "  ⚠ an existing integration could not be refreshed — resolve the error, then run: stable install --refresh-installed"
fi
if [ -n "$BACKUP" ]; then
  if [ "$KEEP_BACKUP" = 0 ]; then
    rm -rf "$BACKUP"
  else
    echo "  → previous app retained at $BACKUP/app until its services have stopped"
  fi
fi

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "  ⚠ $BIN_DIR is not on your PATH — add this to your shell profile:"; echo "      export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

# The Conifer CLI: the Palm broker inside `stable cc` needs it for the gateway catalog.
if [ -z "${STABLE_SKIP_CONIFER:-}" ] && ! command -v conifer >/dev/null 2>&1 && [ ! -x "$BIN_DIR/conifer" ]; then
  echo "  → installing the Conifer CLI (ConiferKit/CLI-release, verified by its own installer)"
  if curl --proto '=https' --tlsv1.2 -fsSL -m 60 -o "$WORK/install-cli.sh" \
       "https://raw.githubusercontent.com/ConiferKit/CLI-release/main/install.sh"; then
    CONIFER_BIN_DIR="$BIN_DIR" sh "$WORK/install-cli.sh" >/dev/null 2>&1 \
      && echo "  ✓ conifer → $BIN_DIR/conifer" \
      || echo "  ⚠ the Conifer CLI installer did not finish — run later: curl -fsSL https://www.conifer.build/install-cli.sh | sh"
  else
    echo "  ⚠ could not fetch the Conifer CLI installer — run later: curl -fsSL https://www.conifer.build/install-cli.sh | sh"
  fi
fi

printf '\n  Checking your existing subscription…\n'
if ! "$APP_HOME/app/stable" status --subscriptions; then
  echo "  ⚠ subscription detection did not finish — retry: stable status --subscriptions"
fi

printf '\n  Next:\n'
echo "    stable codex            launch Codex with your existing ChatGPT login"
echo "    stable login            optional: add a Conifer Gateway key for other models (https://conifer.build/console#/keys)"
echo "    stable install claude-code   wire /harness, /ask, and subagents into Claude Code"
echo "    stable doctor           one line per dependency"
echo "    stable cc | codex | pi  launch a harness on Stable's lanes"
echo
