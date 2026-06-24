#!/usr/bin/env python3
"""Minimal stdio MCP server exposing allowlisted local ml1 operations."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from typing import Any

PROTOCOL_VERSION = "2024-11-05"
SERVER_NAME = "minlang-ml1-bridge"
SERVER_VERSION = "0.1.0"

ALLOWLIST: dict[str, list[str]] = {
	"ml1_features": ["features"],
	"ml1_validate": ["validate"],
	"ml1_graph": ["graph"],
	"ml1_update_check": ["update", "--check"],
}

TOOLS = [
	{
		"name": "ml1_features",
		"description": "Print the embedded MinLang language feature catalog",
		"inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
	},
	{
		"name": "ml1_validate",
		"description": "Run ml1 validate on a MinLang source file",
		"inputSchema": {
			"type": "object",
			"properties": {"file": {"type": "string", "description": "Path to .ml file"}},
			"required": ["file"],
			"additionalProperties": False,
		},
	},
	{
		"name": "ml1_graph",
		"description": "Run ml1 graph on a MinLang source file",
		"inputSchema": {
			"type": "object",
			"properties": {"file": {"type": "string", "description": "Path to .ml file"}},
			"required": ["file"],
			"additionalProperties": False,
		},
	},
	{
		"name": "ml1_update_check",
		"description": "Run ml1 update --check for compiler/bundle/deps drift",
		"inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
	},
]


def send(payload: dict[str, Any]) -> None:
	sys.stdout.write(json.dumps(payload) + "\n")
	sys.stdout.flush()


def missing_ml1_result() -> dict[str, Any]:
	return {
		"content": [
			{
				"type": "text",
				"text": (
					"ml1 is not installed. Install from "
					"https://github.com/codeshift-ai-solutions/minlang-releases "
					"then retry."
				),
			}
		],
		"isError": True,
	}


def run_ml1(args: list[str]) -> dict[str, Any]:
	if shutil.which("ml1") is None:
		return missing_ml1_result()
	try:
		completed = subprocess.run(
			["ml1", *args],
			check=False,
			capture_output=True,
			text=True,
		)
	except OSError as exc:
		return {
			"content": [{"type": "text", "text": f"failed to run ml1: {exc}"}],
			"isError": True,
		}
	output = (completed.stdout or "") + (completed.stderr or "")
	return {
		"content": [{"type": "text", "text": output.strip() or "(no output)"}],
		"isError": completed.returncode != 0,
	}


def handle_call(name: str, arguments: dict[str, Any]) -> dict[str, Any]:
	if name not in ALLOWLIST:
		return {
			"content": [{"type": "text", "text": f"tool not allowlisted: {name}"}],
			"isError": True,
		}
	args = list(ALLOWLIST[name])
	if name in {"ml1_validate", "ml1_graph"}:
		file_path = arguments.get("file")
		if not isinstance(file_path, str) or not file_path.strip():
			return {
				"content": [{"type": "text", "text": "missing required file argument"}],
				"isError": True,
			}
		if ".." in file_path:
			return {
				"content": [{"type": "text", "text": "path traversal rejected"}],
				"isError": True,
			}
		args.append(file_path.strip())
	return run_ml1(args)


def handle_request(msg: dict[str, Any]) -> None:
	method = msg.get("method")
	msg_id = msg.get("id")
	if method == "initialize":
		send(
			{
				"jsonrpc": "2.0",
				"id": msg_id,
				"result": {
					"protocolVersion": PROTOCOL_VERSION,
					"capabilities": {"tools": {}},
					"serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
				},
			}
		)
		return
	if method == "notifications/initialized":
		return
	if method == "tools/list":
		send({"jsonrpc": "2.0", "id": msg_id, "result": {"tools": TOOLS}})
		return
	if method == "tools/call":
		params = msg.get("params") or {}
		name = params.get("name", "")
		arguments = params.get("arguments") or {}
		if not isinstance(arguments, dict):
			arguments = {}
		send(
			{
				"jsonrpc": "2.0",
				"id": msg_id,
				"result": handle_call(str(name), arguments),
			}
		)
		return
	if msg_id is not None:
		send(
			{
				"jsonrpc": "2.0",
				"id": msg_id,
				"error": {"code": -32601, "message": f"method not found: {method}"},
			}
		)


def main() -> None:
	for line in sys.stdin:
		line = line.strip()
		if not line:
			continue
		try:
			msg = json.loads(line)
		except json.JSONDecodeError:
			continue
		if not isinstance(msg, dict):
			continue
		handle_request(msg)


if __name__ == "__main__":
	main()
