#!/bin/sh
# Stable — one-line installer (macOS, Apple Silicon).
#
#   curl -fsSL https://raw.githubusercontent.com/yinan4099/stable-release/main/install.sh | bash
#
# Downloads the latest published stable-macos-arm64.tar.gz from the release
# channel, verifies it against the release's own sha256 asset, unpacks it under
# ~/.stable/app and links ~/.local/bin/stable to it. The app carries its own
# Python interpreter; install each harness CLI separately (Codex can also come
# from its desktop app). Fails CLOSED at every step:
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

WORK="$(mktemp -d "${TMPDIR:-/tmp}/stable-install.XXXXXX")"
INSTALL_LOCK=""
cleanup() {
  rm -rf "$WORK"
  if [ -n "$INSTALL_LOCK" ]; then rmdir "$INSTALL_LOCK" 2>/dev/null || true; fi
}
trap cleanup EXIT

printf '\n  Installing Stable…\n\n'
echo "  Anonymous install and usage counts are on by default. Disable with: stable analytics off"
echo "  No prompts, file paths, credentials or account emails are reported."
if [ -n "${STABLE_INSTALL_VERSION:-}" ]; then
  RELEASE_TAG="$STABLE_INSTALL_VERSION"
else
  # Resolve the moving latest alias ONCE. Separate latest/download requests
  # can reach different releases while publication or CDN caches advance.
  echo "  → resolving the latest release"
  if ! RELEASE_URL="$(curl --proto '=https' --proto-redir '=https' --tlsv1.2 -fsSL -m 60 \
      -H 'Cache-Control: no-cache' -o /dev/null -w '%{url_effective}' \
      "https://github.com/$REPO/releases/latest?stable_install=${WORK##*/}")"; then
    echo "  ✗ the latest Stable release could not be resolved from $REPO — nothing was installed." >&2
    exit 1
  fi
  TAG_PREFIX="https://github.com/$REPO/releases/tag/"
  case "$RELEASE_URL" in
    "$TAG_PREFIX"*) RELEASE_TAG="${RELEASE_URL#"$TAG_PREFIX"}" ;;
    *) RELEASE_TAG="" ;;
  esac
  case "$RELEASE_TAG" in
    ''|*[!a-zA-Z0-9._+%~-]*)
      echo "  ✗ GitHub did not resolve a valid Stable release tag — nothing was installed." >&2
      exit 1 ;;
  esac
fi
BASE="https://github.com/$REPO/releases/download/$RELEASE_TAG"
echo "  → downloading release $RELEASE_TAG"
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
# The downloaded app holds the same lock as current Stable launches and reviews
# for the entire replacement. Keep its original staging payload in place while
# this single apply script runs, including nested integration refresh commands.
export STABLE_INSTALL_APP_HOME="$APP_HOME" STABLE_INSTALL_BIN_DIR="$BIN_DIR"
export STABLE_INSTALL_WORK="$WORK" STABLE_INSTALL_VERSION_TEXT="$VERSION"
cat > "$WORK/apply.sh" <<'STABLE_APPLY'
set -eu
APP_HOME="$STABLE_INSTALL_APP_HOME"
BIN_DIR="$STABLE_INSTALL_BIN_DIR"
WORK="$STABLE_INSTALL_WORK"
VERSION="$STABLE_INSTALL_VERSION_TEXT"
if [ -e "$BIN_DIR/stable" ] || [ -L "$BIN_DIR/stable" ]; then
  if [ ! -L "$BIN_DIR/stable" ] || [ "$(readlink "$BIN_DIR/stable")" != "$APP_HOME/app/stable" ]; then
    echo "  ✗ $BIN_DIR/stable is not the installed Stable app link — it was preserved; move that command before retrying." >&2
    exit 1
  fi
fi
rm -rf "$APP_HOME/app.new"
cp -R "$WORK/unpack/stable" "$APP_HOME/app.new"
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
if ! "$APP_HOME/app/stable" install --record-app >"$WORK/ownership.log" 2>&1; then
  KEEP_BACKUP=1
  cat "$WORK/ownership.log" >&2
  echo "  ⚠ app ownership could not be recorded — retry: stable install --record-app"
fi
if [ -f "$APP_HOME/broker.pid" ]; then
  if "$APP_HOME/app/stable" broker restart >/dev/null 2>&1; then
    echo "  ✓ Stable's provider service restarted on the new app"
  else
    KEEP_BACKUP=1
    echo "  ⚠ Stable's provider service could not be restarted — run: stable broker restart"
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
  cat "$WORK/integration-refresh.log"
  echo "  ✓ refreshed previously installed host integrations"
else
  KEEP_BACKUP=1
  cat "$WORK/integration-refresh.log" >&2
  echo "  ⚠ an existing integration could not be refreshed — resolve the error, then run: stable install --refresh-installed"
fi
# Preserve the user's explicit default choice. Refresh changes only shims that
# were enabled already; a fresh install keeps normal native commands unchanged.
if "$APP_HOME/app/stable" default --refresh >"$WORK/default-refresh.log" 2>&1; then
  cat "$WORK/default-refresh.log"
else
  KEEP_BACKUP=1
  cat "$WORK/default-refresh.log" >&2
  echo "  ⚠ default launchers could not be refreshed — resolve the error, then run: stable default on"
fi
if [ -n "$BACKUP" ]; then
  # Query the renamed executable after the swap: this also catches old clients
  # that entered immediately before replacement, even if argv[0] is just stable.
  if ! "$WORK/unpack/stable/stable" install --old-app-idle "$BACKUP/app/stable"; then
    KEEP_BACKUP=1
  fi
  if [ "$KEEP_BACKUP" = 0 ]; then
    rm -rf "$BACKUP"
  else
    echo "  → previous app retained at $BACKUP/app until its services have stopped"
  fi
fi
STABLE_APPLY
# Keep the staged helper's interpreter and payload until its guarded child
# finishes. Removing WORK on an outer-shell interrupt would break that child.
trap 'echo "  → finishing the guarded app update before cleaning staging files" >&2' INT TERM
if "$WORK/unpack/stable/stable" install --with-update-lock /bin/sh "$WORK/apply.sh"; then
  :
else
  CODE=$?
  if [ "$CODE" = 64 ]; then
    echo "  ✗ this selected release does not support the current guarded installer; use the latest release, or that older release's matching installer." >&2
  fi
  echo "  ✗ update did not finish — resolve the reported issue, then rerun the installer." >&2
  exit "$CODE"
fi
trap - INT TERM

# The installed app owns the reporting preference and payload. Wake its finite
# sender only after the replacement lease is released; never wait for upload.
"$APP_HOME/app/stable" analytics --flush >/dev/null 2>&1 || true

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "  ⚠ $BIN_DIR is not on your PATH — add this to your shell profile:"; echo "      export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

printf '\n  Checking your existing subscription…\n'
if ! "$APP_HOME/app/stable" status --subscriptions; then
  echo "  ⚠ subscription detection did not finish — retry: stable status --subscriptions"
fi
echo "  Run stable to check your current login again; stable codex login signs in if needed."

printf '\n  Preparing private reviewer tools…\n'
if ! "$APP_HOME/app/stable" reviewer setup --install; then
  echo "  ⚠ some reviewer tools need setup — follow the messages above, then run: stable reviewer setup"
fi

# Report the existing login before optional gateway dependency setup, which can
# take longer and is independent of subscription-only use.
# The optional gateway lane uses the Conifer CLI; subscription detection does not.
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

printf '\n  Next:\n'
echo "    stable codex            launch Codex with your existing ChatGPT login"
echo "    stable login            optional: add a Conifer Gateway key for other models (https://conifer.build/console#/keys)"
echo "    stable install claude-code   wire /harness, /ask, and subagents into Claude Code"
echo "    stable doctor           one line per dependency"
echo "    stable default          optional: make native terminal commands launch Stable"
echo "    stable reviewer setup --status   inspect private reviewer tools"
echo "    stable uninstall        remove Stable, preserving native CLIs and logins"
echo "    stable cc | codex | pi  launch a harness on Stable's lanes"
echo
