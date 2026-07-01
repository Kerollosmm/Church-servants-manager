import os
import sys

# Reconfigure stdout to use UTF-8
try:
    sys.stdout.reconfigure(encoding='utf-8')
except:
    pass

recovered_dir = "recovered_blobs"
target_files = {
    "sync_entry.dart": "lib/core/models/sync_entry.dart",
    "sync_handler.dart": "lib/core/services/sync_handler.dart",
    "student_sync_handler.dart": "lib/features/student/data/services/student_sync_handler.dart",
    "attendance_sync_handler.dart": "lib/features/attendance/data/services/attendance_sync_handler.dart",
    "attendance_session_sync_handler.dart": "lib/features/attendance/data/services/attendance_session_sync_handler.dart",
    "results_sync_handler.dart": "lib/features/results/data/services/results_sync_handler.dart",
    "pastoral_sync_handler.dart": "lib/features/student/data/services/pastoral_sync_handler.dart",
    "sync_service.dart": "lib/core/services/sync_service.dart",
    "student_local_datasource.dart": "lib/features/student/data/datasources/student_local_datasource.dart",
    "servant_local_datasource.dart": "lib/features/servant/data/local/servant_local_datasource.dart",
    "servant_data_repository.dart": "lib/features/servant/data/repo/servant_data_repository.dart",
    "student_data_repository.dart": "lib/features/student/data/repos/student_data_repository.dart",
    "attendance_repository.dart": "lib/features/attendance/data/repos/attendance_repository.dart",
    "auth_bloc.dart": "lib/features/auth/presentation/bloc/auth_bloc.dart",
    "church_app.dart": "lib/church_app.dart",
    "injection.dart": "lib/core/di/injection.dart",
    "sync_service_test.dart": "test/core/services/sync_service_test.dart",
    "sync_service_dlq_test.dart": "test/core/services/sync_service_dlq_test.dart"
}

# Extremely relaxed: just match the class/method/test declaration itself!
signatures = {
    "sync_entry.dart": ["class SyncEntry"],
    "sync_handler.dart": ["class SyncHandler"],
    "student_sync_handler.dart": ["class StudentSyncHandler"],
    "attendance_sync_handler.dart": ["class AttendanceSyncHandler"],
    "attendance_session_sync_handler.dart": ["class AttendanceSessionSyncHandler"],
    "results_sync_handler.dart": ["class ResultsSyncHandler"],
    "pastoral_sync_handler.dart": ["class PastoralSyncHandler"],
    "sync_service.dart": ["class SyncService"],
    "student_local_datasource.dart": ["class StudentLocalDatasource"],
    "servant_local_datasource.dart": ["class ServantLocalDatasource"],
    "servant_data_repository.dart": ["class ServantDataRepository"],
    "student_data_repository.dart": ["class StudentDataRepository"],
    "attendance_repository.dart": ["class AttendanceRepository"],
    "auth_bloc.dart": ["class AuthBloc"],
    "church_app.dart": ["class ChurchApp"],
    "injection.dart": ["configureDependencies"],
    "sync_service_test.dart": ["void main()", "SyncService", "test("],
    "sync_service_dlq_test.dart": ["void main()", "DeadLetterQueue", "test("]
}

candidates = {k: [] for k in target_files}

for filename in os.listdir(recovered_dir):
    path = os.path.join(recovered_dir, filename)
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()
        
    if content.startswith("diff --git") or content.startswith("#"):
        continue
        
    for key, sigs in signatures.items():
        if all(sig in content for sig in sigs):
            # For tests, distinguish between sync_service_test and sync_service_dlq_test
            if key == "sync_service_test" and "DeadLetterQueue" in content:
                continue
            if key == "sync_service_dlq_test" and "DeadLetterQueue" not in content:
                continue
                
            lines = len(content.splitlines())
            candidates[key].append((filename, len(content), lines, content[:200]))

print("--- RELAXED CANDIDATE BLOB ANALYSIS ---")
for key, list_candidates in candidates.items():
    print(f"\n{key} ({target_files[key]}): {len(list_candidates)} candidates")
    list_candidates.sort(key=lambda x: x[1], reverse=True)
    for fn, size, lines, snippet in list_candidates[:3]:
        snippet_clean = snippet.replace('\n', ' ').replace('\r', '')
        print(f"  - Blob: {fn} | Size: {size} bytes | Lines: {lines} | Snippet: {snippet_clean[:120]}...")
