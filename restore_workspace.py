import json
import os
from datetime import datetime

conversations = [
    {"id": "ce208102-4f4c-4da6-bb61-e5e42af7a1fd", "title": "Refactoring Outbox Sync Engine"},
    {"id": "4703b39b-2da6-492b-bd74-9da625de881b", "title": "Auditing Servant RBAC Security"},
    {"id": "048146de-57b7-469c-a057-6a37868d6f4d", "title": "Auditing Attendance Feature"},
    {"id": "7180acc3-a774-4a6c-98d4-8985aeb4f612", "title": "Auditing Hive Firestore Sync Engine"},
    {"id": "147b4923-7813-45d9-9e6d-5a77d23d9a9c", "title": "Fixing Broken Flutter Tests"}
]

target_time = datetime.fromisoformat("2026-05-24T19:51:00+00:00")
all_actions = []

for conv in conversations:
    log_path = f"C:\\Users\\KimoStore\\.gemini\\antigravity\\brain\\{conv['id']}\\.system_generated\\logs\\transcript.jsonl"
    if not os.path.exists(log_path):
        print(f"File not found: {log_path}")
        continue
        
    with open(log_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                step = json.loads(line)
                created_at_str = step.get("created_at")
                if not created_at_str:
                    continue
                if created_at_str.endswith("Z"):
                    created_at_str = created_at_str[:-1] + "+00:00"
                dt = datetime.fromisoformat(created_at_str)
                
                tool_calls = step.get("tool_calls", [])
                for tc in tool_calls:
                    name = tc.get("name")
                    if name in ["write_to_file", "replace_file_content", "multi_replace_file_content"]:
                        args = tc.get("args", {})
                        if isinstance(args, str):
                            try:
                                args = json.loads(args)
                            except:
                                pass
                        
                        all_actions.append({
                            "conversation": conv["title"],
                            "timestamp": dt,
                            "tool": name,
                            "args": args
                        })
            except Exception as e:
                pass

# Sort all actions by timestamp
all_actions.sort(key=lambda x: x["timestamp"])

# Filter actions before target time
before_actions = [a for a in all_actions if a["timestamp"] <= target_time]

print(f"Found {len(before_actions)} edits before target time.")

virtual_files = {}

def clean_value(val):
    if isinstance(val, str):
        val = val.strip()
        if val.startswith('"') and val.endswith('"'):
            try:
                # Parse double-quoted string
                val = json.loads(val)
            except:
                val = val[1:-1]
    return val

def get_file_content(path):
    norm_path = os.path.normpath(path).lower()
    if norm_path in virtual_files:
        return virtual_files[norm_path]
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    return None

def set_file_content(path, content):
    norm_path = os.path.normpath(path).lower()
    virtual_files[norm_path] = content

errors = []
applied_count = 0

for idx, action in enumerate(before_actions):
    tool = action["tool"]
    args = action["args"]
    target_file = clean_value(args.get("TargetFile"))
    if not target_file:
        continue
        
    if "antigravity" in target_file.lower() or "brain" in target_file.lower():
        continue
        
    applied_count += 1
    
    if tool == "write_to_file":
        code_content = clean_value(args.get("CodeContent", ""))
        set_file_content(target_file, code_content)
        print(f"Action {idx}: write_to_file {target_file}")
        
    elif tool == "replace_file_content":
        target_content = clean_value(args.get("TargetContent", ""))
        replacement_content = clean_value(args.get("ReplacementContent", ""))
        
        current_content = get_file_content(target_file)
        if current_content is None:
            errors.append(f"Action {idx}: File {target_file} not found for replacement.")
            continue
            
        if target_content not in current_content:
            errors.append(f"Action {idx}: TargetContent not found in {target_file}.\nTargetContent: {repr(target_content[:100])}")
            continue
            
        new_content = current_content.replace(target_content, replacement_content, 1)
        set_file_content(target_file, new_content)
        print(f"Action {idx}: replace_file_content {target_file}")
        
    elif tool == "multi_replace_file_content":
        chunks = args.get("ReplacementChunks", [])
        if isinstance(chunks, str):
            chunks_str = clean_value(chunks)
            # escape control chars inside JSON string literal
            chunks_str = chunks_str.replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t')
            try:
                chunks = json.loads(chunks_str)
            except Exception as e:
                errors.append(f"Action {idx}: Failed to parse chunks string: {e}")
                continue
                
        current_content = get_file_content(target_file)
        if current_content is None:
            errors.append(f"Action {idx}: File {target_file} not found for multi-replacement.")
            continue
            
        new_content = current_content
        chunk_failed = False
        for chunk_idx, chunk in enumerate(chunks):
            if isinstance(chunk, str):
                chunk_str = clean_value(chunk)
                chunk_str = chunk_str.replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t')
                try:
                    chunk = json.loads(chunk_str)
                except Exception as e:
                    errors.append(f"Action {idx} Chunk {chunk_idx}: Failed to parse chunk string: {e}")
                    chunk_failed = True
                    break
            tc = clean_value(chunk.get("TargetContent", ""))
            rc = clean_value(chunk.get("ReplacementContent", ""))
            if tc not in new_content:
                errors.append(f"Action {idx} Chunk {chunk_idx}: TargetContent not found in {target_file}.\nTargetContent: {repr(tc[:100])}")
                chunk_failed = True
                break
            new_content = new_content.replace(tc, rc, 1)
            
        if not chunk_failed:
            set_file_content(target_file, new_content)
            print(f"Action {idx}: multi_replace_file_content {target_file}")

print(f"\nDry Run Complete. Applied {applied_count} edits.")
if errors:
    print(f"Encountered {len(errors)} errors:")
    for err in errors[:20]:
        print(err)
else:
    print("Success! No errors. Writing files to disk...")
    for path, content in virtual_files.items():
        # Ensure directories exist
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(content)
    print(f"Successfully restored {len(virtual_files)} files to the target state!")
