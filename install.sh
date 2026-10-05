#!/usr/bin/env bash
#
# install.sh — installs Go + the recon toolkit (subfinder, httpx, nuclei, ffuf)
# Tested on Linux (amd64). Needs: curl, tar.
#
set -u

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
GO_DIR="$KIT_DIR/.go"
BIN_DIR="$HOME/go/bin"

echo "[*] Installing Go (local to the kit, no sudo needed) ..."
mkdir -p "$KIT_DIR"
curl -sL --max-time 180 -o /tmp/go.tgz https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
tar -xzf /tmp/go.tgz -C "$KIT_DIR" && mv "$KIT_DIR/go" "$GO_DIR"
rm -f /tmp/go.tgz

export PATH="$GO_DIR/bin:$PATH"
export GOBIN="$BIN_DIR"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"
# Go builds in /tmp by default; on small-/tmp systems that fails — use home dir
export GOTMPDIR="$HOME/tmp"
mkdir -p "$GOTMPDIR"

echo "[*] Go $(go version)"
echo "[*] Installing recon tools (this takes a few minutes) ..."
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/ffuf/ffuf/v2@latest

echo "[*] Downloading nuclei templates ..."
nuclei -update-templates -silent

echo
echo "=============================================="
echo " Done! Tools installed to: $BIN_DIR"
echo "=============================================="
echo " Add this to your shell rc (.bashrc/.zshrc):"
echo "   export PATH=\"\$HOME/go/bin:\$PATH\""
echo
echo " Then run:  ./recon.sh <domain>"
echo " (Only against targets you're authorized to test.)"
