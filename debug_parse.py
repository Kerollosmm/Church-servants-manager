import json
import os

log_path = "C:\\Users\\KimoStore\\.gemini\\antigravity\\brain\\147b4923-7813-45d9-9e6d-5a77d23d9a9c\\.system_generated\\logs\\transcript.jsonl"
with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        step = json.loads(line)
        tool_calls = step.get("tool_calls", [])
        for tc in tool_calls:
            name = tc.get("name")
            if name == "multi_replace_file_content":
                print("RAW ARGS:")
                print(tc.get("args"))
                print("TYPE:", type(tc.get("args")))
                break
