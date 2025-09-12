# GhostSay

> **LLM Usage Notice:** This project was designed by [@minhuw](https://github.com/minhuw) and implemented **entirely** by [Claude Code](https://claude.ai/code). Use at your own discretion.

> **Security Notice:** Recommended for deployment on private networks (e.g., Tailscale) to prevent unauthorized access. This project does not implement robust security defenses.

A lightweight macOS menubar app that lets you trigger text-to-speech notifications from any remote machine to alert the poor guy sitting in front of it.

## Usage

**1. Start the application:**
```bash
swift run
```

**2. Control from menubar:**
- Click the speaker icon in your menubar
- Start/stop the HTTP server (default port 5000)
- Change port in Settings if needed

**3. Trigger from remote machines:**
```bash
# Basic usage
curl "http://<YOUR_MAC_IP>:5000/say?text=Hello+World"

# From build scripts
./deploy.sh && curl "http://<YOUR_MAC_IP>:5000/say?text=Deploy+complete"

# From Python
import requests
requests.get("http://<YOUR_MAC_IP>:5000/say", params={"text": "Training finished"})

# From remote servers
ssh user@server 'long_command && curl "http://<YOUR_MAC_IP>:5000/say?text=Job+done"'
```

Replace `YOUR_MAC_IP` with your Mac's Tailscale network IP address. **Warning:** Do not expose this service to the public internet without proper security measures.