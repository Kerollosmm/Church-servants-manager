import 'package:church_managment_system/core/utils/data_seeder.dart';
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
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                        child: const Text('Seed'),
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
