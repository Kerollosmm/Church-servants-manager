import 'dart:async';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/results/data/models/results_model.dart';
import 'package:church_management_system/features/results/presentation/bloc/results_bloc.dart';
import 'package:church_management_system/features/results/presentation/bloc/results_event.dart';
import 'package:church_management_system/features/results/presentation/bloc/results_state.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GradeEntryScreen extends StatefulWidget {
  final AuthUser actor;
  final String groupId;
  final String termId;

  const GradeEntryScreen({
    super.key,
    required this.actor,
    required this.groupId,
    required this.termId,
  });

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ResultsBloc>().add(
      ResultsLoadRequested(groupId: widget.groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رصد الدرجات'), centerTitle: true),
      body: BlocBuilder<StudentDataBloc, StudentDataState>(
        builder: (context, studentState) {
          if (studentState is StudentDataLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (studentState is StudentDataError) {
            return Center(child: Text(studentState.message));
          }
          if (studentState is! StudentDataLoaded) {
            return const Center(child: Text('لا يوجد بيانات مخدومين'));
          }

          final students = studentState.students
              .where((s) => s.group.name == widget.groupId)
              .toList();

          return BlocBuilder<ResultsBloc, ResultsState>(
            builder: (context, resultsState) {
              if (resultsState is ResultsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final resultsMap = <String, ResultsModel>{};
              if (resultsState is ResultsLoaded) {
                for (final result in resultsState.results) {
                  if (result.termId == widget.termId) {
                    resultsMap[result.studentId] = result;
                  }
                }
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: students.length,
                separatorBuilder: (context, index) => AppSpacing.gapMd,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final result = resultsMap[student.docID];
                  return GradeEntryTile(
                    student: student,
                    result: result,
                    termId: widget.termId,
                    groupId: widget.groupId,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class GradeEntryTile extends StatefulWidget {
  final StudentModel student;
  final ResultsModel? result;
  final String termId;
  final String groupId;

  const GradeEntryTile({
    super.key,
    required this.student,
    this.result,
    required this.termId,
    required this.groupId,
  });

  @override
  State<GradeEntryTile> createState() => _GradeEntryTileState();
}

class _GradeEntryTileState extends State<GradeEntryTile> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.result?.score.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final score = double.tryParse(value);
      if (score != null && score >= 0 && score <= 100) {
        context.read<ResultsBloc>().add(
          ResultUpdateRequested(
            result: ResultsModel(
              studentId: widget.student.docID,
              termId: widget.termId,
              score: score,
              groupId: widget.groupId,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(widget.student.name),
        subtitle: Text('الصف: ${widget.student.grade}'),
        trailing: SizedBox(
          width: 80,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0-100',
              border: OutlineInputBorder(),
            ),
            onChanged: _onChanged,
          ),
        ),
      ),
    );
  }
}
