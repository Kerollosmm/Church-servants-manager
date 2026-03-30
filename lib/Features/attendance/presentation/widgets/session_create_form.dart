import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:flutter/material.dart';

class AttendanceSessionDraft {
  const AttendanceSessionDraft({
    required this.team,
    required this.startsAt,
    required this.durationMinutes,
    this.title,
  });

  final TeamModel team;
  final DateTime startsAt;
  final int durationMinutes;
  final String? title;
}

class SessionCreateForm extends StatefulWidget {
  const SessionCreateForm({
    super.key,
    required this.teams,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final List<TeamModel> teams;
  final bool isSubmitting;
  final ValueChanged<AttendanceSessionDraft> onSubmit;

  @override
  State<SessionCreateForm> createState() => _SessionCreateFormState();
}

class _SessionCreateFormState extends State<SessionCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late TeamModel _selectedTeam;
  late DateTime _selectedDateTime;
  final _durationController = TextEditingController(text: '60');

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.teams.first;
    final now = DateTime.now();
    _selectedDateTime = DateTime(now.year, now.month, now.day, now.hour, 0);
  }

  @override
  void didUpdateWidget(covariant SessionCreateForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.teams.contains(_selectedTeam) && widget.teams.isNotEmpty) {
      _selectedTeam = widget.teams.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDateTime,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final duration = int.parse(_durationController.text.trim());
    widget.onSubmit(
      AttendanceSessionDraft(
        team: _selectedTeam,
        startsAt: _selectedDateTime,
        durationMinutes: duration,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<TeamModel>(
            initialValue: _selectedTeam,
            decoration: const InputDecoration(
              labelText: 'الفريق',
              border: OutlineInputBorder(),
            ),
            items: widget.teams
                .map(
                  (team) => DropdownMenuItem<TeamModel>(
                    value: team,
                    child: Text(team.name),
                  ),
                )
                .toList(growable: false),
            onChanged: widget.isSubmitting
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _selectedTeam = value);
                  },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الجلسة (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'المدة بالدقائق',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final parsed = int.tryParse(value?.trim() ?? '');
              if (parsed == null || parsed <= 0 || parsed > 480) {
                return 'أدخل مدة صحيحة بين 1 و 480 دقيقة';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.isSubmitting ? null : _pickDateTime,
            icon: const Icon(Icons.schedule),
            label: Text(
              'موعد البدء: ${MaterialLocalizations.of(context).formatFullDate(_selectedDateTime)} ${TimeOfDay.fromDateTime(_selectedDateTime).format(context)}',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.isSubmitting ? null : _submit,
            icon: widget.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: const Text('إنشاء الجلسة'),
          ),
        ],
      ),
    );
  }
}
