import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders student details', (tester) async {
    final student = StudentModel(
      uid: 'student-1',
      docID: 'doc-1',
      name: 'Test Student',
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: 'Team A',
      motherPhone: '01111111111',
      fatherPhone: '02222222222',
      grade: 8,
      educationStage: EducationStage.preparatory,
      school: 'Test School',
      address: 'Test Address',
      birthdate: DateTime(2010, 5, 1),
      fatherOfConfession: 'Fr. Test',
      notes: 'Good student',
      classId: 'year1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudentDetailScreen(
          args: StudentDetailArgs(
            actor: const AuthUser(
              uid: 'admin',
              email: 'admin@test.com',
              name: 'Admin',
              role: UserRole.admin,
            ),
            student: student,
          ),
        ),
      ),
    );

    expect(find.text('Student Details'), findsOneWidget);
    expect(find.text('Test Student'), findsWidgets);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('01234567890'), findsOneWidget);
    expect(find.text('Mother Phone'), findsOneWidget);
    expect(find.text('01111111111'), findsOneWidget);
    expect(find.text('Father Phone'), findsOneWidget);
    expect(find.text('02222222222'), findsOneWidget);
  });
}
