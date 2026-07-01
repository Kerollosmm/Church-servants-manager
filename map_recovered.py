import os
import sys

# Reconfigure stdout to use UTF-8
try:
    sys.stdout.reconfigure(encoding='utf-8')
except:
    pass

recovered_dir = "recovered_blobs"
if not os.path.exists(recovered_dir):
    print("No recovered directory found.")
    exit(1)

# Relaxed patterns to check presence in file content
file_keywords = {
    "sync_entry.dart": ["class SyncEntry", "SyncEntry"],
    "sync_handler.dart": ["abstract class SyncHandler", "SyncHandler"],
    "student_sync_handler.dart": ["class StudentSyncHandler", "StudentSyncHandler"],
    "attendance_sync_handler.dart": ["class AttendanceSyncHandler", "AttendanceSyncHandler"],
    "attendance_session_sync_handler.dart": ["class AttendanceSessionSyncHandler", "AttendanceSessionSyncHandler"],
    "results_sync_handler.dart": ["class ResultsSyncHandler", "ResultsSyncHandler"],
    "pastoral_sync_handler.dart": ["class PastoralSyncHandler", "PastoralSyncHandler"],
    "sync_service.dart": ["class SyncService", "SyncService"],
    "student_local_datasource.dart": ["class StudentLocalDatasource", "StudentLocalDatasource"],
    "servant_local_datasource.dart": ["class ServantLocalDatasource", "ServantLocalDatasource"],
    "servant_data_repository.dart": ["class ServantDataRepository", "ServantDataRepository"],
    "student_data_repository.dart": ["class StudentDataRepository", "StudentDataRepository"],
    "attendance_repository.dart": ["class AttendanceRepository", "AttendanceRepository"],
    "auth_bloc.dart": ["class AuthBloc", "AuthBloc"],
    "church_app.dart": ["class ChurchApp", "ChurchApp"],
    "injection.dart": ["configureDependencies", "registerFallbackValue"],
    "sync_service_test.dart": ["group('SyncService'", "group(\"SyncService\""],
    "sync_service_dlq_test.dart": ["group('SyncService DeadLetterQueue'", "group(\"SyncService DeadLetterQueue\""]
}

matches = {k: [] for k in file_keywords}

for filename in os.listdir(recovered_dir):
    path = os.path.join(recovered_dir, filename)
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()
        
    for name, keywords in file_keywords.items():
        # check if any of the keywords are present
        found = False
        for kw in keywords:
            if kw in content:
                found = True
                break
        if found:
            snippet = content[:80].replace('\n', ' ').replace('\r', '')
            # Clean snippet for stdout printing
            clean_snippet = "".join([c if ord(c) < 128 else '?' for c in snippet])
            matches[name].append((filename, len(content), clean_snippet))

print("--- RECOVERED BLOB MAPPINGS ---")
for name, list_matches in matches.items():
    print(f"\n{name}: {len(list_matches)} matches")
    # Sort by size descending
    list_matches.sort(key=lambda x: x[1], reverse=True)
    for fn, size, snippet in list_matches[:5]:
        print(f"  - {fn} | Size: {size} bytes | Snippet: {snippet}...")
