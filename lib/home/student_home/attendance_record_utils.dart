import 'package:classlens/api/api.dart';
import 'package:classlens/data_models/subjects.dart';

DateTime? attendanceRecordDate(Map<String, dynamic> record) {
  for (final key in ['marked_at', 'date', 'class_datetime', 'created_at']) {
    final value = record[key];
    if (value == null) {
      continue;
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed != null) {
      return parsed.toLocal();
    }
  }

  return null;
}

String attendanceRecordSubject(Map<String, dynamic> record) {
  for (final key in ['subject', 'subject_name', 'name']) {
    final value = record[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }

  return 'Subject';
}

String normalizeSubjectKey(dynamic value) {
  return value?.toString().trim().toLowerCase() ?? '';
}

String subjectIdentityKey(Map<String, dynamic> subject) {
  for (final key in ['code', 'subject_code', 'name', 'subject_name']) {
    final value = subject[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return normalizeSubjectKey(value);
    }
  }

  return '';
}

Map<String, dynamic> mergeSubjectMetadata(
  Map<String, dynamic> source,
  Map<String, dynamic> fallback,
) {
  final merged = <String, dynamic>{...fallback};

  for (final entry in source.entries) {
    final key = entry.key.toString();
    if (entry.value == null) {
      continue;
    }

    if (key == 'teacher' ||
        key == 'teacher_name' ||
        key == 'division_name' ||
        key == 'division' ||
        key == 'division_id' ||
        key == 'year' ||
        key == 'semester' ||
        key == 'academic_year') {
      merged[key] = entry.value;
    }
  }

  return merged;
}

String attendanceRecordSubjectKey(Map<String, dynamic> record) {
  for (final key in ['subject_code', 'code', 'subject', 'subject_name', 'name']) {
    final value = record[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return normalizeSubjectKey(value);
    }
  }

  return '';
}

int? attendanceRecordStudentId(Map<String, dynamic> record) {
  for (final key in ['student_id', 'studentID']) {
    final value = record[key];
    if (value == null) {
      continue;
    }

    final parsed = int.tryParse(value.toString());
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

String attendanceRecordStudentPrn(Map<String, dynamic> record) {
  for (final key in ['student_prn', 'prn']) {
    final value = record[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }

  return '';
}

bool recordMatchesStudent(Map<String, dynamic> record, {int? studentId, String? studentPrn}) {
  if (studentId == null && (studentPrn == null || studentPrn.trim().isEmpty)) {
    return true;
  }

  final recordStudentId = attendanceRecordStudentId(record);
  if (studentId != null && recordStudentId != null) {
    return recordStudentId == studentId;
  }

  final recordStudentPrn = attendanceRecordStudentPrn(record);
  if (studentPrn != null && studentPrn.trim().isNotEmpty && recordStudentPrn.isNotEmpty) {
    return recordStudentPrn == studentPrn.trim();
  }

  return studentId == null && (studentPrn == null || studentPrn.trim().isEmpty);
}

List<Map<String, dynamic>> filterAttendanceByStudent(
  Iterable<Map<String, dynamic>> records, {
  int? studentId,
  String? studentPrn,
}) {
  return records.where((record) => recordMatchesStudent(
        record,
        studentId: studentId,
        studentPrn: studentPrn,
      )).toList();
}

bool recordMatchesSubjectKeys(
  Map<String, dynamic> record,
  Set<String> allowedKeys,
) {
  if (allowedKeys.isEmpty) {
    return true;
  }

  final key = attendanceRecordSubjectKey(record);
  if (key.isEmpty) {
    return true;
  }

  return allowedKeys.contains(key);
}

List<Map<String, dynamic>> filterAttendanceBySubjectKeys(
  Iterable<Map<String, dynamic>> records,
  Set<String> allowedKeys,
) {
  return records.where((record) => recordMatchesSubjectKeys(record, allowedKeys)).toList();
}

String attendanceRecordStatus(Map<String, dynamic> record) {
  for (final key in ['status', 'attendance_status']) {
    final value = record[key];
    if (value == null) {
      continue;
    }

    if (value is bool) {
      return value ? 'Present' : 'Absent';
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      continue;
    }

    final normalized = text.toLowerCase();
    if (normalized == 'true' || normalized == 'present' || normalized == '1') {
      return 'Present';
    }

    if (normalized == 'false' || normalized == 'absent' || normalized == '0') {
      return 'Absent';
    }

    return text;
  }

  return 'Unknown';
}

int? attendanceRecordYear(Map<String, dynamic> record) {
  for (final key in ['year', 'academic_year']) {
    final value = record[key];
    if (value == null) {
      continue;
    }

    final parsed = int.tryParse(value.toString());
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

int? attendanceRecordSemester(Map<String, dynamic> record) {
  for (final key in ['semester', 'sem']) {
    final value = record[key];
    if (value == null) {
      continue;
    }

    final parsed = int.tryParse(value.toString());
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

bool matchesAcademicPeriod(
  Map<String, dynamic> record, {
  int? year,
  int? semester,
}) {
  final recordYear = attendanceRecordYear(record);
  final recordSemester = attendanceRecordSemester(record);

  final yearMatches = year == null || recordYear == null || recordYear == year;
  final semesterMatches = semester == null || recordSemester == null || recordSemester == semester;
  return yearMatches && semesterMatches;
}

List<Map<String, dynamic>> filterAttendanceByAcademicPeriod(
  Iterable<Map<String, dynamic>> records, {
  int? year,
  int? semester,
}) {
  return records.where((record) => matchesAcademicPeriod(
        record,
        year: year,
        semester: semester,
      )).toList();
}

String _firstNonEmptyString(Map<String, dynamic> record, List<String> keys) {
  for (final key in keys) {
    final value = record[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }

  return '';
}

String attendanceRecordIdentity(Map<String, dynamic> record) {
  final explicitId = _firstNonEmptyString(
    record,
    ['class_session_id', 'session_id', 'attendance_id', 'id'],
  );
  if (explicitId.isNotEmpty) {
    return 'id:$explicitId';
  }

  final date = attendanceRecordDate(record)?.toUtc().toIso8601String() ??
      _firstNonEmptyString(record, ['marked_at', 'date', 'class_datetime', 'created_at']);
  final subject = attendanceRecordSubject(record);
  final status = attendanceRecordStatus(record);
  return 'fallback:$subject|$status|$date';
}

List<Map<String, dynamic>> normalizeAttendanceRecords(Iterable<Map<String, dynamic>> records) {
  final seen = <String>{};
  final normalized = <Map<String, dynamic>>[];

  for (final record in records) {
    final identity = attendanceRecordIdentity(record);
    if (seen.add(identity)) {
      normalized.add(record);
    }
  }

  normalized.sort((left, right) {
    final leftDate = attendanceRecordDate(left) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final rightDate = attendanceRecordDate(right) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return rightDate.compareTo(leftDate);
  });

  return normalized;
}

Map<String, Map<String, int>> summarizeAttendanceBySubject(List<Map<String, dynamic>> records) {
  final summaries = <String, Map<String, int>>{};

  for (final record in records) {
    final subject = attendanceRecordSubject(record);
    final status = attendanceRecordStatus(record).toLowerCase();
    final summary = summaries.putIfAbsent(subject, () => {'attended': 0, 'total': 0});

    summary['total'] = (summary['total'] ?? 0) + 1;
    if (status == 'present') {
      summary['attended'] = (summary['attended'] ?? 0) + 1;
    }
  }

  return summaries;
}

String _subjectDisplayName(Subjects subject) {
  final name = subject.name.trim();
  if (name.isNotEmpty) {
    return name;
  }

  return subject.code.trim();
}

Set<String> subjectKeysForAttendance(List<Subjects> subjects) {
  final keys = <String>{};

  for (final subject in subjects) {
    final codeKey = normalizeSubjectKey(subject.code);
    final nameKey = normalizeSubjectKey(subject.name);
    if (codeKey.isNotEmpty) {
      keys.add(codeKey);
    }
    if (nameKey.isNotEmpty) {
      keys.add(nameKey);
    }
  }

  return keys;
}

Map<String, dynamic> _decorateAttendanceRecord(
  Map<String, dynamic> record,
  Subjects subject,
) {
  final decorated = Map<String, dynamic>.from(record);
  final subjectName = _subjectDisplayName(subject);
  final subjectCode = subject.code.trim();

  if ((decorated['subject']?.toString().trim() ?? '').isEmpty) {
    decorated['subject'] = subjectName;
  }

  if ((decorated['subject_name']?.toString().trim() ?? '').isEmpty) {
    decorated['subject_name'] = subjectName;
  }

  if (subjectCode.isNotEmpty) {
    if ((decorated['subject_code']?.toString().trim() ?? '').isEmpty) {
      decorated['subject_code'] = subjectCode;
    }

    if ((decorated['code']?.toString().trim() ?? '').isEmpty) {
      decorated['code'] = subjectCode;
    }
  }

  return decorated;
}

Future<List<Map<String, dynamic>>> loadStudentAttendanceRecords({
  required List<Subjects> semesterSubjects,
  required Map<String, dynamic> dashboardData,
  int? studentId,
  String? studentPrn,
}) async {
  final fallbackRecentActivity = List<Map<String, dynamic>>.from(
    dashboardData['recent_activity'] ?? const [],
  );
  final subjectKeys = subjectKeysForAttendance(semesterSubjects);

  if (semesterSubjects.isNotEmpty) {
    final fetchedRecords = await Future.wait(
      semesterSubjects.map((subject) async {
        if (subject.id <= 0) {
          return const <Map<String, dynamic>>[];
        }

        final records = await ApiServices.getStudentSubjectAttendance(
          subjectId: subject.id,
        );

        return records
            .map((record) => _decorateAttendanceRecord(record, subject))
            .toList();
      }),
    );

    final combinedFetchedRecords = normalizeAttendanceRecords(
      filterAttendanceByStudent(
        subjectKeys.isNotEmpty
            ? filterAttendanceBySubjectKeys(
                fetchedRecords.expand((records) => records).toList(),
                subjectKeys,
              )
            : fetchedRecords.expand((records) => records).toList(),
        studentId: studentId,
        studentPrn: studentPrn,
      ),
    );

    if (combinedFetchedRecords.isNotEmpty) {
      return combinedFetchedRecords;
    }
  }

  final normalizedRecords = normalizeAttendanceRecords(
    filterAttendanceByStudent(
      subjectKeys.isNotEmpty
          ? filterAttendanceBySubjectKeys(fallbackRecentActivity, subjectKeys)
          : fallbackRecentActivity,
      studentId: studentId,
      studentPrn: studentPrn,
    ),
  );

  return normalizedRecords;
}