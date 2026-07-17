enum SyncActionType {
  markAttendance('MARK_ATTENDANCE'),
  clearAttendance('CLEAR_ATTENDANCE'),
  closeSession('CLOSE_SESSION'),
  createSession('CREATE_SESSION'),
  updateResult('UPDATE_RESULT'),
  createServant('CREATE_SERVANT'),
  updateServant('UPDATE_SERVANT'),
  archiveServant('ARCHIVE_SERVANT'),
  restoreServant('RESTORE_SERVANT'),
  createPastoralRecord('CREATE_PASTORAL_RECORD'),
  upsertStudent('UPSERT_STUDENT'),
  createStudentInvitation('CREATE_STUDENT_INVITATION'),
  archiveStudent('ARCHIVE_STUDENT'),
  restoreStudent('RESTORE_STUDENT'),
  createTeam('CREATE_TEAM'),
  updateTeam('UPDATE_TEAM'),
  deleteTeam('DELETE_TEAM'),
  restoreTeam('RESTORE_TEAM');

  final String value;
  const SyncActionType(this.value);

  static SyncActionType? fromValue(String value) {
    for (final type in SyncActionType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
