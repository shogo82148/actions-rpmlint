#!/usr/bin/env python3

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path


MAX_OUTPUT_LENGTH = 60_000


def pull_request_number(event_path: str) -> int | None:
    try:
        event = json.loads(Path(event_path).read_text(encoding="utf-8"))
        return int(event["pull_request"]["number"])
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError):
        return None


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: post-pr-comment.py OUTPUT_FILE", file=sys.stderr)
        return 1

    token = os.environ.get("INPUT_GITHUB_TOKEN", "")
    repository = os.environ.get("GITHUB_REPOSITORY", "")
    event_path = os.environ.get("GITHUB_EVENT_PATH", "")
    number = pull_request_number(event_path) if event_path else None

    if not token or not repository or number is None:
        print(
            "Skipping pull request comment: this is not a pull request run or "
            "GitHub credentials are unavailable."
        )
        return 0

    output = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
    if len(output) > MAX_OUTPUT_LENGTH:
        output = output[:MAX_OUTPUT_LENGTH] + "\n… (output truncated)"

    body = "## rpmlint failed\n\n````text\n" + output.rstrip() + "\n````"
    api_url = os.environ.get("GITHUB_API_URL", "https://api.github.com").rstrip("/")
    url = f"{api_url}/repos/{repository}/issues/{number}/comments"
    request = urllib.request.Request(
        url,
        data=json.dumps({"body": body}).encode("utf-8"),
        method="POST",
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "actions-rpmlint",
            "X-GitHub-Api-Version": "2026-03-10",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=30):
            pass
    except (urllib.error.URLError, TimeoutError) as error:
        print(f"Could not post pull request comment: {error}", file=sys.stderr)
        return 1

    print(f"Posted rpmlint failure details to pull request #{number}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
