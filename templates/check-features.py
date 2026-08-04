#!/usr/bin/env python3
"""Enforce the features.json contract in CI.

An agent may only flip `passes` from false to true, and only after actually
running the entry's `verify` command. It may never delete an entry, never edit a
description, and never flip a passing feature back to false to make a task look
complete.

Usage: check-features.py <base.json> <head.json>
"""
import json
import sys


def load(path):
    with open(path) as fh:
        return {f["id"]: f for f in json.load(fh).get("features", [])}


def main():
    if len(sys.argv) != 3:
        print("usage: check-features.py <base.json> <head.json>", file=sys.stderr)
        return 2

    base, head = load(sys.argv[1]), load(sys.argv[2])
    errors = []

    for fid, bf in base.items():
        hf = head.get(fid)
        if hf is None:
            errors.append(f"feature '{fid}' was deleted")
            continue
        if bf.get("passes") is True and hf.get("passes") is not True:
            errors.append(f"feature '{fid}' regressed from passes=true to passes=false")
        if bf.get("description") != hf.get("description"):
            errors.append(f"feature '{fid}' description was edited")

    for err in errors:
        print(f"::error::{err}")

    if errors:
        return 1

    print(f"features.json OK ({len(head)} features, {sum(1 for f in head.values() if f.get('passes'))} passing)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
