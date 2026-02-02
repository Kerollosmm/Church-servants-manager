import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen that displays a list of students.
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  @override
  void initState() {
    super.initState();
    // Load students when screen opens
    context.read<StudentDataBloc>().add(const StudentsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<StudentDataBloc, StudentDataState>(
        listener: (context, state) {
          if (state is StudentDataError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is StudentDataOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is StudentDataLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudentDataLoaded) {
            if (state.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No students found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<StudentDataBloc>().add(
                          const StudentsRefreshRequested(),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<StudentDataBloc>();
                // Wait for next non-loading state
                final future = bloc.stream.firstWhere(
                  (state) => state is! StudentDataLoading,
                );
                bloc.add(const StudentsRefreshRequested());
                await future;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.students.length,
                itemBuilder: (context, index) {
                  final student = state.students[index];
                  return _StudentCard(student: student);
                },
              ),
            );
          }

          // Initial or error state - show retry button
          return Center(
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<StudentDataBloc>().add(
                  const StudentsLoadRequested(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Load Students'),
            ),
          );
        },
      ),
    );
  }
}

/// Card widget displaying student information.
class _StudentCard extends StatefulWidget {
  final StudentModel student;

  const _StudentCard({required this.student});

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  bool _imageLoadFailed = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final showImage = student.imageUrl != null && !_imageLoadFailed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          backgroundImage: showImage ? NetworkImage(student.imageUrl!) : null,
          onBackgroundImageError: showImage
              ? (_, e) {
                  if (mounted) setState(() => _imageLoadFailed = true);
                }
              : null,
          child: !showImage
              ? Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grade: ${student.grade}'),
            Text(
              'Group: ${student.group.name}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Colors.teal),
          onPressed: () {
            // TODO: Implement call functionality
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Call ${student.mobile}')));
          },
        ),
      ),
    );
  }
}
