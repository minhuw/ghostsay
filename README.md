# GhostSay

> **LLM Usage Notice:** This project was designed by [@minhuw](https://github.com/minhuw) and implemented **entirely** by [Claude Code](https://claude.ai/code). Use at your own discretion.

> **Security Notice:** Recommended for deployment on private networks (e.g., Tailscale) to prevent unauthorized access. This project does not implement robust security defenses.

A lightweight macOS menubar app that lets you trigger text-to-speech notifications from any remote machine to alert the poor guy sitting in front of it.

## Usage

**1. Install:**
- Download the latest `GhostSay-*.dmg` from [Releases](https://github.com/minhuw/ghostsay/releases)
- Open the DMG and drag GhostSay to Applications

**2. Control from menubar:**
- Click the speaker icon in your menubar
- Start/stop the HTTP server (default port 57630)
- Change IP address and port in Settings if needed

**3. Trigger from remote machines:**
```bash
# Basic usage
curl "http://<YOUR_MAC_IP>:57630/say?text=Hello+World"

# From build scripts
./deploy.sh && curl "http://<YOUR_MAC_IP>:57630/say?text=Deploy+complete"

# From Python
import requests
requests.get("http://<YOUR_MAC_IP>:57630/say", params={"text": "Training finished"})

# From remote servers
ssh user@server 'long_command && curl "http://<YOUR_MAC_IP>:57630/say?text=Job+done"'

# As Claude Code stop hook
curl -s "http://<YOUR_MAC_IP>:57630/say?text=node%20$(hostname)%20mission%20accomplished.%20Standby" > /dev/null 2>&1 || true
```

**Claude Code hooks example** (`~/.claude/settings.json`):
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "curl -s \"http://<YOUR_MAC_IP>:57630/say?text=node%20$(hostname)%20mission%20accomplished.%20Standby\" > /dev/null 2>&1 || true"
          }
        ]
      }
    ]
  }
}
```

Replace `YOUR_MAC_IP` with your Mac's Tailscale network IP address. **Warning:** Do not expose this service to the public internet without proper security measures.