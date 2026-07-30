import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/utils/data_seeder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  final _seeder = DataSeeder();
  final _countController = TextEditingController(text: '20');
  Group _selectedGroup = Group.year1;
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _status = success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(
          child: Text('Dev Tools are only available in debug mode.'),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Role Assignment (Debug Only)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Group>(
                    initialValue: _selectedGroup,
                    decoration: const InputDecoration(
                      labelText: 'Target Group for Teacher/Student',
                    ),
                    items: Group.values.map((g) {
                      return DropdownMenuItem(
                        value: g,
                        child: Text('${g.displayName} (${g.name})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedGroup = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                _seeder.assignMeAsAdmin,
                                'Role set to Admin.',
                              ),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Assign Me as Admin'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => _seeder.assignMeAsTeacher(
                                  group: _selectedGroup,
                                ),
                                'Role set to Servant/Teacher (${_selectedGroup.name}).',
                              ),
                        icon: const Icon(Icons.person_pin),
                        label: const Text('Assign Me as Teacher'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => _seeder.assignMeAsStudentAndCreateProfile(
                                  group: _selectedGroup,
                                ),
                                'Role set to Student and profile created.',
                              ),
                        icon: const Icon(Icons.school),
                        label: const Text('Assign Me as Student'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seeder',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(_seeder.seedTeams, 'Teams seeded.'),
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('Seed Teams (3 per Group)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _countController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Students Count',
                            prefixIcon: Icon(Icons.numbers_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () {
                                final count =
                                    int.tryParse(_countController.text) ?? 20;
                                _run(
                                  () => _seeder.seedStudents(count: count),
                                  'Seeded $count students.',
                                );
                              },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                        child: const Text('Seed'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Reset Data',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () {
                            final count =
                                int.tryParse(_countController.text) ?? 20;
                            _run(
                              () => _seeder.clearAndReseed(studentCount: count),
                              'Cleared old data & reseeded $count students.',
                            );
                          },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear & Reseed All'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  _seeder.clearStudents,
                                  'All students cleared.',
                                ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Clear Students'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  _seeder.clearTeams,
                                  'All teams cleared.',
                                ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Clear Teams'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(
              _status!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _status!.startsWith('Error')
                    ? colorScheme.error
                    : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
