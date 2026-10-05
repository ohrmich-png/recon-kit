# 🔍 Recon Kit

A simple bug-bounty recon pipeline. One command, organized results.

## Setup (one time)

```bash
chmod +x install.sh recon.sh
./install.sh
# then add to your shell rc:
export PATH="$HOME/go/bin:$PATH"
```

This installs Go (locally, no sudo) plus:
| Tool | What it does |
|---|---|
| **subfinder** | Finds subdomains of a target domain |
| **httpx** | Probes which hosts are live, grabs titles + tech stack |
| **nuclei** | Scans live hosts for known vulnerabilities |
| **ffuf** | (installed, for manual use) Fast content/directory fuzzing |

## Usage

```bash
./recon.sh example.com
```

Runs the full pipeline and drops everything into `results/example.com/<timestamp>/`:
- `subdomains.txt` — all discovered subdomains
- `live.txt` — live hosts with status code, title, tech, IP
- `nuclei.txt` — vulnerability findings (if any)
- `SUMMARY.txt` — the one-page overview: start here

## The workflow (how to use the output)

1. **Read SUMMARY.txt** — how big is the attack surface?
2. **Skim `live.txt`** — look for interesting tech (old WordPress, Jenkins, Grafana, dev/staging subdomains, login pages).
3. **Check `nuclei.txt`** — automated findings are *leads*, not bounties. **Verify each one manually** before believing it.
4. **Go manual** — the real bugs come from creative probing of the interesting hosts: auth flows, IDORs, business logic. Point Burp at the juicy targets.
5. **ffuf for content discovery** on a promising host:
   ```bash
   ffuf -u https://target.example.com/FUZZ -w /path/to/wordlist.txt -mc 200,301,302,403
   ```

## Rules (non-negotiable)

- **Only test in-scope targets** — read the program's policy before running anything.
- Never touch other users' real data. Stop the moment you've proved the issue.
- Automated findings need **manual verification** — unverified AI/tool output is the slop that gets researchers gated.

## Next steps

After recon: pick the 2–3 most interesting hosts, proxy them through Burp Suite, and hunt manually. That's where bounties live.
