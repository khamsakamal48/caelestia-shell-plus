#!/usr/bin/env python3
"""Claude plan usage for the dashboard's AI Usage tab, printed as JSON.

Uses the OAuth token Claude Code keeps in ~/.claude/.credentials.json against
the endpoint behind Claude Code's own /usage (as Ryoku's claude-usage does).
Token counts are summed locally from Claude Code's session logs. A result
younger than two minutes is reused so reopening the dashboard stays offline.
"""
import json, time, urllib.request
from datetime import datetime, timedelta
from pathlib import Path

HOME = Path.home()
CREDS = HOME / ".claude/.credentials.json"
PROJECTS = HOME / ".claude/projects"
CACHE = HOME / ".cache/caelestia/claude-usage.json"
ENDPOINT = "https://api.anthropic.com/api/oauth/usage"


def fetch(token):
    req = urllib.request.Request(ENDPOINT, headers={
        "Authorization": f"Bearer {token}",
        "anthropic-beta": "oauth-2025-04-20",
        "User-Agent": "claude-code/2.0.0",
    })
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.load(r)


def window(w):
    w = w or {}
    reset = w.get("resets_at")
    return {
        "percent": (w.get("utilization") or 0) / 100,
        "reset": int(datetime.fromisoformat(reset.replace("Z", "+00:00")).timestamp()) if reset else 0,
    }


def tokens_by_day(days=7):
    """Local-date token totals for the last `days` days, oldest first."""
    today = datetime.now().date()
    keys = [(today - timedelta(days=i)).isoformat() for i in range(days - 1, -1, -1)]
    totals = dict.fromkeys(keys, 0)
    since = time.time() - days * 86400
    for f in PROJECTS.glob("**/*.jsonl"):
        try:
            if f.stat().st_mtime < since:
                continue
            for line in f.open():
                if '"usage"' not in line:
                    continue
                e = json.loads(line)
                msg = e.get("message") or {}
                if msg.get("role") != "assistant" or not e.get("timestamp"):
                    continue
                day = datetime.fromisoformat(e["timestamp"].replace("Z", "+00:00")).astimezone().date().isoformat()
                if day in totals:
                    u = msg.get("usage") or {}
                    totals[day] += sum(u.get(k) or 0 for k in ("input_tokens", "output_tokens",
                                                             "cache_read_input_tokens", "cache_creation_input_tokens"))
        except Exception:
            continue
    return [{"date": k, "tokens": totals[k]} for k in keys]


def main():
    try:
        if time.time() - CACHE.stat().st_mtime < 120:
            print(CACHE.read_text())
            return
    except OSError:
        pass

    try:
        token = json.loads(CREDS.read_text())["claudeAiOauth"]["accessToken"]
    except Exception:
        print(json.dumps({"error": "login"}))
        return

    try:
        data = fetch(token)
    except Exception as e:
        # Keep the last numbers on screen, flagged stale (e.g. token expired while Claude Code is closed)
        try:
            out = json.loads(CACHE.read_text()) | {"stale": True}
        except Exception:
            out = {"error": "expired" if getattr(e, "code", 0) == 401 else "fetch"}
        print(json.dumps(out))
        return

    out = {
        "fiveHour": window(data.get("five_hour")),
        "sevenDay": window(data.get("seven_day")),
        "days": tokens_by_day(),
        "updated": int(time.time()),
    }
    text = json.dumps(out)
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(text)
    print(text)


if __name__ == "__main__":
    main()
