import 'dart:async';
import 'dart:io';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/student/data/datasources/student_local_datasource.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncService extends Mock implements SyncService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late StudentLocalDatasource localDatasource;
  late MockSyncService mockSyncService;
  late StudentDataRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('student_repo_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(SyncEntryAdapter());
    Hive.registerAdapter(UserRoleAdapter());
    Hive.registerAdapter(EducationStageAdapter());
    Hive.registerAdapter(SyncStatusAdapter());
    Hive.registerAdapter(GroupAdapter());
    Hive.registerAdapter(StudentModelAdapter());
    registerFallbackValue(
      SyncEntry(
        id: 'fallback',
        actionType: 'UPSERT_STUDENT',
        payload: {},
        createdAt: DateTime.now(),
      ),
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    localDatasource = StudentLocalDatasource();
    mockSyncService = MockSyncService();

    // Clear boxes if open
    if (Hive.isBoxOpen(StudentLocalDatasource.boxName)) {
      await Hive.box<StudentModel>(StudentLocalDatasource.boxName).clear();
    }
    if (Hive.isBoxOpen('sync_queue_box')) {
      await Hive.box<SyncEntry>('sync_queue_box').clear();
    }

    repository = StudentDataRepository(
      firestore: firestore,
      localDatasource: localDatasource,
      syncServiceGetter: () => mockSyncService,
    );

    when(() => mockSyncService.enqueue(any())).thenAnswer((_) async {});
    when(() => mockSyncService.processQueue()).thenAnswer((_) async {});
  });

  group('StudentDataRepository', () {
    test(
      'createStudent enqueues CREATE_STUDENT_INVITATION and does not store password in Hive',
      () async {
        final student = Student(
          uid: '',
          docID: '',
          name: 'Test Student',
          role: UserRole.student,
          mobile: '01234567890',
          group: Group.year1,
          teamName: 'Team A',
          motherPhone: '01234567890',
          fatherPhone: '01234567890',
          grade: 1,
          educationStage: EducationStage.preparatory,
          fatherOfConfession: 'Fr. Test',
          classId: 'team1',
        );

        final docId = await repository.createStudent(
          student,
          email: 'test@example.com',
        );

        expect(docId, isNotEmpty);

        // Verify sync entry was enqueued
        final captured =
            verify(() => mockSyncService.enqueue(captureAny())).captured.single
                as SyncEntry;
        expect(captured.actionType, 'CREATE_STUDENT_INVITATION');
        expect(captured.payload['email'], 'test@example.com');
        expect(captured.payload.containsKey('password'), isFalse);

        // Verify student stored in local datasource
        final local = await localDatasource.getStudent(docId);
        expect(local, isNotNull);
        expect(local!.name, 'Test Student');
        expect(local.syncStatus, SyncStatus.pending);
      },
    );

    test(
      'createStudent throws ArgumentFailure when docId matches email',
      () async {
        final student = Student(
          uid: '',
          docID: 'test@example.com',
          name: 'Test Student',
          role: UserRole.student,
          mobile: '01234567890',
          group: Group.year1,
          teamName: 'Team A',
          motherPhone: '01234567890',
          fatherPhone: '01234567890',
          grade: 1,
          educationStage: EducationStage.preparatory,
          fatherOfConfession: 'Fr. Test',
          classId: 'team1',
        );

        expect(
          () => repository.createStudent(student, email: 'test@example.com'),
          throwsA(isA<ArgumentFailure>()),
        );
      },
    );

    test(
      'archive -> restore -> archive same docId enqueues distinct suffixed IDs',
      () async {
        final studentObj = Student(
          uid: 'u1',
          docID: 's1',
          name: 'Test Student',
          role: UserRole.student,
          mobile: '01234567890',
          group: Group.year1,
          teamName: 'Team A',
          motherPhone: '01234567890',
          fatherPhone: '01234567890',
          grade: 1,
          educationStage: EducationStage.preparatory,
          fatherOfConfession: 'Fr. Test',
          classId: 'team1',
        );

        // Seed student locally
        await localDatasource.saveStudent(StudentModel.fromDomain(studentObj));

        // 1. Archive
        await repository.archiveStudent('s1', performedByUid: 'actor1');
        // 2. Restore
        await repository.restoreStudent('s1', performedByUid: 'actor1');
        // 3. Archive
        await repository.archiveStudent('s1', performedByUid: 'actor1');

        final captured = verify(
          () => mockSyncService.enqueue(captureAny()),
        ).captured;
        expect(captured.length, 3);

        final entry1 = captured[0] as SyncEntry;
        final entry2 = captured[1] as SyncEntry;
        final entry3 = captured[2] as SyncEntry;

        expect(entry1.actionType, 'ARCHIVE_STUDENT');
        expect(entry2.actionType, 'RESTORE_STUDENT');
        expect(entry3.actionType, 'ARCHIVE_STUDENT');

        expect(entry1.id, isNot(equals(entry2.id)));
        expect(entry2.id, isNot(equals(entry3.id)));
        expect(entry1.id, isNot(equals(entry3.id)));
      },
    );

    test(
      'syncBatchedStudents updates multiple students in Firestore and cache',
      () async {
        final entries = [
          SyncEntry(
            id: '1',
            actionType: 'UPSERT_STUDENT',
            payload: {
              'student': {
                'docID': 'stud_1',
                'uid': '',
                'name': 'Student One',
                'role': 'student',
                'mobile': '01234567890',
                'group': 'year1',
                'teamName': 'Team A',
                'classId': 'team1',
                'grade': 1,
                'educationStage': 'preparatory',
                'fatherOfConfession': '',
              },
            },
            createdAt: DateTime.now(),
          ),
          SyncEntry(
            id: '2',
            actionType: 'CREATE_STUDENT_INVITATION',
            payload: {
              'email': 'stud2@example.com',
              'student': {
                'docID': 'stud_2',
                'uid': '',
                'name': 'Student Two',
                'role': 'student',
                'mobile': '01234567890',
                'group': 'year1',
                'teamName': 'Team A',
                'classId': 'team1',
                'grade': 1,
                'educationStage': 'preparatory',
                'fatherOfConfession': '',
              },
            },
            createdAt: DateTime.now(),
          ),
        ];

        await repository.syncBatchedStudents(entries);

        // Verify Firestore writes
        final doc1 = await firestore.collection('Students').doc('stud_1').get();
        expect(doc1.exists, isTrue);
        expect(doc1.data()?['name'], 'Student One');

        final doc2 = await firestore.collection('Students').doc('stud_2').get();
        expect(doc2.exists, isTrue);
        expect(doc2.data()?['name'], 'Student Two');

        final invite = await firestore
            .collection('Invitations')
            .doc('stud2@example.com')
            .get();
        expect(invite.exists, isTrue);
        expect(invite.data()?['email'], 'stud2@example.com');

        // Verify cache updates
        final cache1 = await localDatasource.getStudent('stud_1');
        expect(cache1, isNotNull);
        expect(cache1!.syncStatus, SyncStatus.synced);

        final cache2 = await localDatasource.getStudent('stud_2');
        expect(cache2, isNotNull);
        expect(cache2!.syncStatus, SyncStatus.synced);
      },
    );

    test(
      'syncBatchedStudents handles >450 entries successfully (chunkedBatch verification)',
      () async {
        final entries = List.generate(460, (i) {
          return SyncEntry(
            id: 'entry_$i',
            actionType: 'UPSERT_STUDENT',
            payload: {
              'student': {
                'docID': 'stud_$i',
                'uid': '',
                'name': 'Student $i',
                'role': 'student',
                'mobile': '01234567890',
                'group': 'year1',
                'teamName': 'Team A',
                'classId': 'team1',
                'grade': 1,
                'educationStage': 'preparatory',
                'fatherOfConfession': '',
              },
            },
            createdAt: DateTime.now(),
          );
        });

        await repository.syncBatchedStudents(entries);

        // Verify a sampling of documents
        final doc0 = await firestore.collection('Students').doc('stud_0').get();
        expect(doc0.exists, isTrue);

        final doc455 = await firestore
            .collection('Students')
            .doc('stud_455')
            .get();
        expect(doc455.exists, isTrue);
      },
    );
  });
}
