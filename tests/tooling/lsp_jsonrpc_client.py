#!/usr/bin/env python3
"""Minimal stdio JSON-RPC client used by the LuaLS integration spec."""

import argparse
import json
import os
import select
import subprocess
import sys
import time


def send(process, message):
    body = json.dumps(message, separators=(",", ":")).encode()
    process.stdin.write(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
    process.stdin.flush()


def receive(process, request_id, timeout=15):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ready, _, _ = select.select([process.stdout], [], [], deadline - time.monotonic())
        if not ready:
            break
        headers = {}
        while True:
            line = process.stdout.readline()
            if not line or line in (b"\n", b"\r\n"):
                break
            key, value = line.decode().split(":", 1)
            headers[key.lower()] = value.strip()
        length = int(headers.get("content-length", "0"))
        if not length:
            continue
        message = json.loads(process.stdout.read(length))
        if message.get("id") == request_id:
            return message
    raise RuntimeError(f"timed out waiting for JSON-RPC response {request_id}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--server", required=True)
    parser.add_argument("--workspace", required=True)
    parser.add_argument("--uri", required=True)
    parser.add_argument("--logpath", required=True)
    args = parser.parse_args()

    process = subprocess.Popen(
        [args.server, "--stdio", f"--logpath={args.logpath}"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    try:
        send(process, {
            "jsonrpc": "2.0", "id": 1, "method": "initialize",
            "params": {
                "processId": None,
                "rootUri": f"file://{args.workspace}",
                "capabilities": {"textDocument": {"hover": {}, "completion": {}}},
            },
        })
        receive(process, 1)
        send(process, {"jsonrpc": "2.0", "method": "initialized", "params": {}})

        source = open(args.uri.removeprefix("file://"), encoding="utf-8").read()
        send(process, {
            "jsonrpc": "2.0", "method": "textDocument/didOpen",
            "params": {"textDocument": {
                "uri": args.uri, "languageId": "lua", "version": 1, "text": source,
            }},
        })
        # LuaLS indexes the workspace and applies OnSetText asynchronously.
        # Keep this bounded pause before asking for semantic responses.
        time.sleep(1)
        send(process, {
            "jsonrpc": "2.0", "id": 2, "method": "textDocument/hover",
            "params": {"textDocument": {"uri": args.uri}, "position": {"line": 3, "character": 15}},
        })
        hover = receive(process, 2)
        send(process, {
            "jsonrpc": "2.0", "id": 3, "method": "textDocument/completion",
            "params": {"textDocument": {"uri": args.uri}, "position": {"line": 5, "character": 16}},
        })
        completion = receive(process, 3)
        print(json.dumps({"hover": hover, "completion": completion}))
        send(process, {"jsonrpc": "2.0", "id": 4, "method": "shutdown", "params": None})
        receive(process, 4)
        send(process, {"jsonrpc": "2.0", "method": "exit", "params": {}})
    finally:
        process.terminate()
        process.wait(timeout=5)


if __name__ == "__main__":
    main()
