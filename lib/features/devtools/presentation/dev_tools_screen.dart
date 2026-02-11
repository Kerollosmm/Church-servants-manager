import 'package:church_managment_system/core/utils/data_seeder.dart';
import 'package:church_managment_system/core/constants/enums.dart';
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
                    'Seeder',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () =>
                              _run(() => _seeder.seedTeams(), 'Teams seeded.'),
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
                        child: const Text('Seed'),
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
                    'Set My Role',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => _seeder.assignMeAsAdmin(),
                            'You are now Admin. Pull-to-refresh role.',
                          ),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Assign Me as Admin'),
                  ),
                  const SizedBox(height: 12),
                  DropdownMenu<Group>(
                    initialSelection: _selectedGroup,
                    enabled: !_busy,
                    dropdownMenuEntries: Group.values
                        .map((g) => DropdownMenuEntry(value: g, label: g.name))
                        .toList(),
                    onSelected: (g) {
                      if (g == null) return;
                      setState(() => _selectedGroup = g);
                    },
                    label: const Text('Teacher Group'),
                    leadingIcon: const Icon(Icons.group_outlined),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => _seeder.assignMeAsTeacher(
                              group: _selectedGroup,
                            ),
                            'You are now Teacher for ${_selectedGroup.name}. Pull-to-refresh role.',
                          ),
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('Assign Me as Teacher'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => _seeder.assignMeAsStudentAndCreateProfile(),
                            'You are now Student. Pull-to-refresh role.',
                          ),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Assign Me as Student + Create Profile'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seeder cannot create Firebase Auth accounts. It only writes Firestore docs and updates your current user role.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
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
