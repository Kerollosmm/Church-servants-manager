import 'dart:math';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DataSeeder {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid;
  final Random _random;

  DataSeeder({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Uuid? uuid,
    Random? random,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _uuid = uuid ?? const Uuid(),
        _random = random ?? Random();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection(FirestoreCollections.students);

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection(FirestoreCollections.classes);

  /// Creates class documents for year1/year2/year3.
  Future<void> seedClasses() async {
    final now = Timestamp.now();
    for (final group in Group.values) {
      await _classes.doc(group.name).set(
        {
          'name': group.name,
          'group': group.name,
          'createdAt': now,
        },
        SetOptions(merge: true),
      );
    }
    debugPrint('DataSeeder: Classes seeded.');
  }

  /// Seeds demo student documents (not tied to Firebase Auth accounts).
  Future<void> seedStudents({int count = 20}) async {
    const firstNames = [
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

    const lastNames = [
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

    const streets = [
      'Ramsis St.',
      'Shoubra St.',
      'Port Said St.',
      'El-Gomhouria St.',
      'El-Geish St.',
      'Naguib Mahfouz St.',
    ];

    const areas = ['Shoubra', 'El-Sahel', 'Rod El-Farag', 'El-Khalafawy'];

    const fathersOfConfession = [
      'Fr. Daoud',
      'Fr. Bishoy',
      'Fr. Angelos',
      'Fr. Moses',
      'Fr. Raphael',
    ];

    const schools = [
      'Saint Mary School',
      'The Holy Family School',
      'College de la Salle',
      'Notre Dame',
      'Ramses College',
      'Saint George School',
    ];

    for (int i = 0; i < count; i++) {
      final uid = _uuid.v4();
      final docRef = _students.doc();
      final docId = docRef.id;

      final firstName = firstNames[_random.nextInt(firstNames.length)];
      final lastName = lastNames[_random.nextInt(lastNames.length)];
      final fullName = '$firstName $lastName';

      final group = Group.values[_random.nextInt(Group.values.length)];
      final stage =
          EducationStage.values[_random.nextInt(EducationStage.values.length)];

      final grade = switch (group) {
        Group.year1 => 1,
        Group.year2 => 2,
        Group.year3 => 3,
      };

      final student = StudentModel(
        uid: uid,
        docID: docId,
        name: fullName,
        imageUrl: null,
        role: UserRole.student,
        mobile: _randomPhone(),
        group: group,
        teamName: 'Team ${String.fromCharCode(65 + _random.nextInt(5))}',
        motherPhone: _randomPhone(),
        fatherPhone: _randomPhone(),
        grade: grade,
        educationStage: stage,
        school: schools[_random.nextInt(schools.length)],
        address:
            '${_random.nextInt(100) + 1} ${streets[_random.nextInt(streets.length)]}, ${areas[_random.nextInt(areas.length)]}',
        birthdate: DateTime.now().subtract(
          Duration(days: 365 * (12 + _random.nextInt(10))),
        ),
        fatherOfConfession:
            fathersOfConfession[_random.nextInt(fathersOfConfession.length)],
        notes: _random.nextBool() ? 'Active student' : null,
        classId: group.name, // year1/year2/year3
      );

      await docRef.set(student.toMap());
      debugPrint('DataSeeder: Seeded student $fullName ($docId)');
    }

    debugPrint('DataSeeder: Student seeding complete.');
  }

  /// Sets current user role to admin.
  Future<void> assignMeAsAdmin() async {
    final uid = _currentUid();
    await _users.doc(uid).set(
      {
        'uid': uid,
        'role': UserRole.admin.name,
      },
      SetOptions(merge: true),
    );
    debugPrint('DataSeeder: Set current user as admin.');
  }

  /// Sets current user role to teacher (servant) and assigns a groupId: year1/year2/year3.
  Future<void> assignMeAsTeacher({required Group group}) async {
    final uid = _currentUid();
    await _users.doc(uid).set(
      {
        'uid': uid,
        'role': UserRole.servant.name,
        'groupId': group.name,
      },
      SetOptions(merge: true),
    );
    debugPrint('DataSeeder: Set current user as teacher for ${group.name}.');
  }

  /// Sets current user role to student and creates/updates a StudentModel profile for them.
  /// Also mirrors the StudentModel snapshot into Users/{uid} (merge).
  Future<void> assignMeAsStudentAndCreateProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in.');

    final uid = user.uid;
    final displayName = user.displayName ?? user.email?.split('@').first ?? 'Student';

    await _users.doc(uid).set(
      {
        'uid': uid,
        'email': user.email ?? '',
        'name': displayName,
        'role': UserRole.student.name,
        'isEmailVerified': user.emailVerified,
        'groupId': null,
      },
      SetOptions(merge: true),
    );

    final group = Group.year1;
    final student = StudentModel(
      uid: uid,
      docID: uid, // stable ID for self profile
      name: displayName,
      imageUrl: null,
      role: UserRole.student,
      mobile: _randomPhone(),
      group: group,
      teamName: 'Team A',
      motherPhone: _randomPhone(),
      fatherPhone: _randomPhone(),
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: 'Fr. (unset)',
      notes: null,
      classId: group.name,
    );

    await _students.doc(uid).set(student.toMap(), SetOptions(merge: true));
    await _users.doc(uid).set(student.toMap(), SetOptions(merge: true));

    debugPrint('DataSeeder: Set current user as student and created profile.');
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

