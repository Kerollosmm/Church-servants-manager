import subprocess
import os
import re

# Directory to save recovered files
recovered_dir = "recovered_blobs"
os.makedirs(recovered_dir, exist_ok=True)

# Run git fsck to get all dangling blobs
print("Running git fsck --lost-found...")
result = subprocess.run(["git", "fsck", "--lost-found"], capture_output=True, text=True, cwd="c:\\Users\\KimoStore\\church_managment_system")

blobs = []
for line in result.stdout.splitlines():
    if "dangling blob" in line:
        parts = line.split()
        if len(parts) >= 3:
            blobs.append(parts[2])

print(f"Found {len(blobs)} dangling blobs. Inspecting contents...")

keywords = ["SyncService", "AuthBloc", "pastoral", "servant", "student", "AttendanceBloc", "IAttendanceRepository", "DeadLetterQueue", "HivePruningService"]

recovered_count = 0
for idx, blob in enumerate(blobs):
    # Get content of the blob
    content_res = subprocess.run(["git", "cat-file", "-p", blob], capture_output=True, text=True, encoding='utf-8', errors='ignore', cwd="c:\\Users\\KimoStore\\church_managment_system")
    content = content_res.stdout
    
    # Check if any keyword matches
    matched = [kw for kw in keywords if kw in content]
    if matched:
        # Determine likely filename or content type
        first_line = content.splitlines()[0] if content.splitlines() else ""
        
        # Save to recovered_blobs directory
        filename = os.path.join(recovered_dir, f"{blob[:8]}_{matched[0]}.dart")
        with open(filename, "w", encoding="utf-8") as f:
            f.write(content)
            
        print(f"[{idx+1}/{len(blobs)}] Recovered blob {blob[:8]} (matches: {matched}) -> {filename}")
        recovered_count += 1

print(f"\nCompleted! Recovered {recovered_count} files containing keywords to the '{recovered_dir}' folder.")
