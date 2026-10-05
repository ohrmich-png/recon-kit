#!/usr/bin/env bash
#
# recon.sh — Bug bounty recon pipeline (Or's kit)
# Usage: ./recon.sh <domain>
#
# Pipeline: subfinder (subdomain enum) → httpx (probe live hosts + tech detect)
#           → nuclei (vuln scan) → organized results with a summary.
#
# IMPORTANT: only run this against targets you are authorized to test
# (in-scope bug bounty program assets, or your own systems).
#
set -u

DOMAIN="${1:-}"
if [[ -z "$DOMAIN" ]]; then
  echo "Usage: $0 <domain>"
  echo "Example: $0 example.com"
  exit 1
fi

# --- tool check -------------------------------------------------------------
for tool in subfinder httpx nuclei; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: '$tool' not found. Run ./install.sh first (or add it to PATH)."
    exit 1
  fi
done

# --- setup ------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="results/${DOMAIN}/${STAMP}"
mkdir -p "$OUT"
echo "[*] Target : $DOMAIN"
echo "[*] Output : $OUT"
echo

# --- 1. subdomain enumeration -------------------------------------------------
echo "[1/3] subfinder — enumerating subdomains of $DOMAIN ..."
subfinder -d "$DOMAIN" -silent -o "$OUT/subdomains.txt" < /dev/null 2>"$OUT/subfinder.err"
SUBS=$(wc -l < "$OUT/subdomains.txt" | tr -d ' ')
if [[ "$SUBS" -eq 0 ]]; then
  # No subdomains found — the bare domain itself is still a valid target
  echo "      → no subdomains found, falling back to the bare domain"
  echo "$DOMAIN" > "$OUT/subdomains.txt"
  SUBS=1
else
  echo "      → $SUBS subdomains found"
fi

# --- 2. probe live hosts ------------------------------------------------------
echo "[2/3] httpx — probing for live web hosts + tech detection ..."
httpx -l "$OUT/subdomains.txt" -silent \
  -status-code -title -tech-detect -ip \
  -o "$OUT/live.txt" < /dev/null 2>"$OUT/httpx.err"
LIVE=$(wc -l < "$OUT/live.txt" | tr -d ' ')
echo "      → $LIVE live hosts"

# --- 3. vulnerability scan ----------------------------------------------------
echo "[3/3] nuclei — scanning live hosts (this takes a while) ..."
nuclei -l "$OUT/live.txt" -silent \
  -severity low,medium,high,critical \
  -o "$OUT/nuclei.txt" < /dev/null 2>"$OUT/nuclei.err"
FINDINGS=$(grep -c . "$OUT/nuclei.txt" 2>/dev/null || true)
FINDINGS=${FINDINGS:-0}
echo "      → $FINDINGS findings"

# --- summary ------------------------------------------------------------------
{
  echo "=============================================="
  echo " RECON SUMMARY — $DOMAIN ($STAMP)"
  echo "=============================================="
  echo " Subdomains : $SUBS"
  echo " Live hosts : $LIVE"
  echo " Findings   : $FINDINGS"
  echo
  echo " Files:"
  echo "  subdomains.txt  — all discovered subdomains"
  echo "  live.txt        — live hosts (status, title, tech, IP)"
  echo "  nuclei.txt      — vulnerability findings"
  echo
  if [[ "$FINDINGS" -gt 0 ]]; then
    echo " Top findings:"
    head -20 "$OUT/nuclei.txt" | sed 's/^/  /'
  fi
} | tee "$OUT/SUMMARY.txt"

echo
echo "[*] Done. Results in $OUT"
