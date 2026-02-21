#!/usr/bin/env python3
"""Normalize Codex CLI JSONL output to the harness output contract.

Reads JSONL events from stdin, extracts result text and usage metrics,
and writes a single JSON object to stdout matching the adapter contract.

Codex JSONL event types:
  thread.started   → {thread_id}
  turn.started     → {}
  item.completed   → {item: {id, type, text?, content?}}
  turn.completed   → {usage: {input_tokens, output_tokens, cached_input_tokens}}
  thread.completed → {}
"""

import json
import sys
import time


def normalize():
    start_time = time.monotonic()
    events = []

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            continue

    duration_ms = int((time.monotonic() - start_time) * 1000)

    # Extract result text from the last agent_message item.completed event.
    # Codex may use either item.text (simple) or item.content[].text (structured).
    result_text = ""
    for e in reversed(events):
        if e.get("type") == "item.completed":
            item = e.get("item", {})
            # Try direct text field first (observed in practice)
            if item.get("text"):
                result_text = item["text"]
                break
            # Fall back to content array (structured output)
            for c in item.get("content", []):
                if c.get("type") == "output_text" and c.get("text"):
                    result_text = c["text"]
                    break
            if result_text:
                break

    # Aggregate usage from turn.completed events
    total_input = 0
    total_output = 0
    total_cached = 0
    num_turns = 0
    for e in events:
        if e.get("type") == "turn.completed":
            num_turns += 1
            usage = e.get("usage", {})
            total_input += usage.get("input_tokens", 0)
            total_output += usage.get("output_tokens", 0)
            total_cached += usage.get("cached_input_tokens", 0)

    # Session ID from thread.started
    session_id = None
    for e in events:
        if e.get("type") == "thread.started":
            session_id = e.get("thread_id")
            break

    output = {
        "result": result_text,
        "total_cost_usd": None,
        "duration_ms": duration_ms,
        "duration_api_ms": None,
        "num_turns": num_turns or None,
        "session_id": session_id,
        "usage": {
            "input_tokens": total_input,
            "output_tokens": total_output,
            "cache_read_input_tokens": total_cached,
            "cache_creation_input_tokens": 0,
        }
        if num_turns > 0
        else None,
        "modelUsage": None,
    }
    json.dump(output, sys.stdout)


if __name__ == "__main__":
    normalize()
