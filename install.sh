#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/jojo-chaechae/plasmusic-toolbar"
BRANCH="${PLASMUSIC_BRANCH:-main}"
SOURCE="$(mktemp -d)"
TMP_APP=$(mktemp --suffix=.plasmusic-toolbar)

trap 'rm -rf "$SOURCE" "$TMP_APP"' EXIT

echo "==> Cloning PlasMusic Toolbar ($BRANCH) ..."
git clone --depth 1 --branch "$BRANCH" "$REPO" "$SOURCE" >/dev/null 2>&1

echo "==> Installing widget ..."
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q '^plasmusic-toolbar'; then
    kpackagetool6 -t Plasma/Applet -u "$SOURCE/src/"
else
    kpackagetool6 -t Plasma/Applet -i "$SOURCE/src/"
fi

echo ""
echo "==> PlasMusic Toolbar installed."
read -r -p "Restart PlasmaShell now? [y/N] " answer
if [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]; then
    plasmashell --replace &>/dev/null &
fi
