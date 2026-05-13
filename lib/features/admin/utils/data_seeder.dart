import 'dart:math';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DataSeeder {
  static const List<String> _studentFirstNames = [
    'Kyrellos',
    'Marina',
    'George',
    'Maria',
    'Mina',
    'Sarah',
    'David',
    'Christine',
    'Peter',
    'Mary',
    'Bishoy',
    'Irini',
    'Tony',
    'Sandra',
    'Mark',
    'Veronia',
    'John',
    'Demiana',
    'Youssef',
    'Nermien',
  ];

  static const List<String> _studentLastNames = [
    'Nabil',
    'Sameh',
    'Girgis',
    'Adel',
    'Tawfik',
    'Yacoub',
    'Fawzy',
    'Ibrahim',
    'Shenouda',
    'Fanous',
    'Mikhail',
    'Botros',
    'Makram',
    'Isaac',
    'Hanna',
    'Sidhom',
    'Ghabrial',
    'Soliman',
  ];

  static const List<String> _studentStreets = [
    'Ramsis St.',
    'Shoubra St.',
    'Port Said St.',
    'El-Gomhouria St.',
    'El-Geish St.',
    'Naguib Mahfouz St.',
  ];

  static const List<String> _studentAreas = [
    'Shoubra',
    'El-Sahel',
    'Rod El-Farag',
    'El-Khalafawy',
  ];

  static const List<String> _studentFathersOfConfession = [
    'Fr. Daoud',
    'Fr. Bishoy',
    'Fr. Angelos',
    'Fr. Moses',
    'Fr. Raphael',
  ];

  static const List<String> _studentSchools = [
    'Saint Mary School',
    'The Holy Family School',
    'College de la Salle',
    'Notre Dame',
    'Ramses College',
    'Saint George School',
  ];

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid;
  final Random _random;

  DataSeeder({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Uuid? uuid,
    Random? random,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _uuid = uuid ?? const Uuid(),
       _random = random ?? Random();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection(FirestoreCollections.students);

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection(FirestoreCollections.classes);

  /// Creates sample teams (Team A, Team B, etc.) for each Group.
  Future<void> seedTeams() async {
    final teamsData = [
      'St. Mark',
      'St. George',
      'St. Mary',
      'St. Mina',
      'St. Bishoy',
    ];

    for (final group in Group.values) {
      for (int i = 0; i < 3; i++) {
        final teamName = '${teamsData[i]} (${group.name})';
        final teamId = _uuid.v4();

        final team = TeamModel(id: teamId, name: teamName, groupId: group.name);

        await _classes.doc(teamId).set(team.toJson());
      }
    }
    _log('DataSeeder: Teams seeded.');
  }

  /// Seeds demo student documents (not tied to Firebase Auth accounts).
  Future<void> seedStudents({int count = 20}) async {
    final teamsByGroup = count > 0
        ? await _loadSeedTeamsByGroup()
        : const <Group, List<TeamModel>>{};

    for (int i = 0; i < count; i++) {
      final uid = _uuid.v4();
      final docRef = _students.doc();
      final docId = docRef.id;

      final firstName =
          _studentFirstNames[_random.nextInt(_studentFirstNames.length)];
      final lastName =
          _studentLastNames[_random.nextInt(_studentLastNames.length)];
      final fullName = '$firstName $lastName';

      final group = Group.values[_random.nextInt(Group.values.length)];
      final stage =
          EducationStage.values[_random.nextInt(EducationStage.values.length)];

      final grade = switch (group) {
        Group.year1 => 1,
        Group.year2 => 2,
        Group.year3 => 3,
      };

      final teamsForGroup = teamsByGroup[group] ?? const <TeamModel>[];

      String teamId = 'temp_team_id';
      String teamName = 'Team A';

      if (teamsForGroup.isNotEmpty) {
        final randomTeam = teamsForGroup[_random.nextInt(teamsForGroup.length)];
        teamId = randomTeam.id;
        teamName = randomTeam.name;
      }

      final student = StudentModel(
        uid: uid,
        docID: docId,
        name: fullName,
        imageUrl: null,
        role: UserRole.student,
        mobile: _randomPhone(),
        group: group,
        teamName: teamName,
        motherPhone: _randomPhone(),
        fatherPhone: _randomPhone(),
        grade: grade,
        educationStage: stage,
        school: _studentSchools[_random.nextInt(_studentSchools.length)],
        address:
            '${_random.nextInt(100) + 1} ${_studentStreets[_random.nextInt(_studentStreets.length)]}, ${_studentAreas[_random.nextInt(_studentAreas.length)]}',
        birthdate: DateTime.now().subtract(
          Duration(days: 365 * (12 + _random.nextInt(10))),
        ),
        fatherOfConfession:
            _studentFathersOfConfession[_random.nextInt(
              _studentFathersOfConfession.length,
            )],
        notes: _random.nextBool() ? 'Active student' : null,
        classId: teamId, // Now correctly linking to a Team ID
      );

      await docRef.set(student.toMap());
      _log('DataSeeder: Seeded student record ${i + 1}/$count');
    }

    _log('DataSeeder: Student seeding complete.');
  }

  Future<Map<Group, List<TeamModel>>> _loadSeedTeamsByGroup() async {
    final entries = await Future.wait(
      Group.values.map((group) async {
        final teamsSnapshot = await _classes
            .where('groupId', isEqualTo: group.name)
            .limit(5)
            .get();
        final teams = teamsSnapshot.docs
            .map((teamDoc) => TeamModel.fromJson(teamDoc.data()))
            .toList(growable: false);
        return MapEntry(group, teams);
      }),
    );

    return Map<Group, List<TeamModel>>.fromEntries(entries);
  }

  /// Deletes ALL documents from the Students collection in paginated batches.
  Future<void> clearStudents() async {
    if (!kDebugMode) return;
    await _clearCollection(_students, 'students');
  }

  /// Deletes ALL documents from the Classes (Teams) collection in paginated batches.
  Future<void> clearTeams() async {
    if (!kDebugMode) return;
    await _clearCollection(_classes, 'teams');
  }

  /// Deletes all documents in [collection] using paginated batches of 400.
  Future<void> _clearCollection(
    CollectionReference<Map<String, dynamic>> collection,
    String label,
  ) async {
    if (!kDebugMode) return;
    int totalDeleted = 0;
    const batchSize = 400;
    QuerySnapshot<Map<String, dynamic>> snapshot;
    do {
      snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      totalDeleted += snapshot.docs.length;
    } while (snapshot.docs.length == batchSize);
    _log('DataSeeder: Cleared $totalDeleted $label.');
  }

  /// Clears all seeded data and reseeds from scratch.
  Future<void> clearAndReseed({int studentCount = 20}) async {
    if (!kDebugMode) return;
    await clearStudents();
    await clearTeams();
    await seedTeams();
    await seedStudents(count: studentCount);
    _log('DataSeeder: Clear & Reseed complete.');
  }

  /// Sets current user role to admin. Debug-only.
  Future<void> assignMeAsAdmin() async {
    assert(kDebugMode, 'assignMeAsAdmin must not be called in release builds');
    if (!kDebugMode) return;
    final uid = _currentUid();
    await _users.doc(uid).set({
      'uid': uid,
      'role': UserRole.admin.name,
    }, SetOptions(merge: true));
    _log('DataSeeder: Set current user as admin.');
  }

  /// Sets current user role to teacher (servant) and assigns a groupId. Debug-only.
  Future<void> assignMeAsTeacher({required Group group}) async {
    assert(
      kDebugMode,
      'assignMeAsTeacher must not be called in release builds',
    );
    if (!kDebugMode) return;
    // Assign to a random team in that group
    final teamsSnapshot = await _classes
        .where('groupId', isEqualTo: group.name)
        .limit(1)
        .get();

    String? assignedTeamId;
    if (teamsSnapshot.docs.isNotEmpty) {
      assignedTeamId = teamsSnapshot.docs.first.id;
    }

    final uid = _currentUid();
    final payload = <String, dynamic>{
      'uid': uid,
      'role': UserRole.servant.name,
      'group': group.name,
      'groupId': group.name,
    };
    if (assignedTeamId != null) {
      payload['assignedTeamId'] = assignedTeamId;
    }
    await _users.doc(uid).set(payload, SetOptions(merge: true));

    _log(
      'DataSeeder: Set current user as teacher for ${group.name} (Team: $assignedTeamId).',
    );
  }

  /// Sets current user role to student and creates/updates a StudentModel profile. Debug-only.
  Future<void> assignMeAsStudentAndCreateProfile() async {
    assert(
      kDebugMode,
      'assignMeAsStudentAndCreateProfile must not be called in release builds',
    );
    if (!kDebugMode) return;
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in.');

    final uid = user.uid;
    final displayName =
        user.displayName ?? user.email?.split('@').first ?? 'Student';

    await _users.doc(uid).set({
      'uid': uid,
      'email': user.email ?? '',
      'name': displayName,
      'role': UserRole.student.name,
      'isEmailVerified': user.emailVerified,
      'groupId': null,
    }, SetOptions(merge: true));

    final group = Group.year1;

    // Fetch a valid team for Year 1
    final teamsSnapshot = await _classes
        .where('groupId', isEqualTo: group.name)
        .limit(1)
        .get();

    String teamId = 'temp_team_id';
    String teamName = 'Team A';

    if (teamsSnapshot.docs.isNotEmpty) {
      final teamData = TeamModel.fromJson(teamsSnapshot.docs.first.data());
      teamId = teamData.id;
      teamName = teamData.name;
    }

    final student = StudentModel(
      uid: uid,
      docID: uid, // stable ID for self profile
      name: displayName,
      imageUrl: null,
      role: UserRole.student,
      mobile: _randomPhone(),
      group: group,
      teamName: teamName,
      motherPhone: _randomPhone(),
      fatherPhone: _randomPhone(),
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: 'Fr. (unset)',
      notes: null,
      classId: teamId,
    );

    await _students.doc(uid).set(student.toMap(), SetOptions(merge: true));

    _log('DataSeeder: Set current user as student and created profile.');
  }

  String _currentUid() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in.');
    return user.uid;
  }

  String _randomPhone() {
    // Simple demo phone generator.
    final prefix = '01${_random.nextInt(3)}';
    final number = (_random.nextInt(8999999) + 1000000).toString();
    return '$prefix$number';
  }
}
