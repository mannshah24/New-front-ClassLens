class TeacherSubjects{
  final int id;
  final String subjectCode;
  final String subjectName;
  final int strength;
  final int? divisionId;
  final String? divisionName;
  final String? departmentName;
  final int? year;
  final int? semester;
  final bool isMapped;

  const TeacherSubjects({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.strength,
    this.divisionId,
    this.divisionName,
    this.departmentName,
    this.year,
    this.semester,
    this.isMapped = true,
  });

  factory TeacherSubjects.fromJson(Map<String,dynamic> json){
    final dynamic codeValue = json['code'] ?? json['subject_code'] ?? json['subject__code'] ?? '';
    final dynamic nameValue = json['name'] ?? json['subject_name'] ?? json['subject__name'] ?? '';
    final dynamic strengthValue = json['strength'] ?? json['student_count'] ?? 0;
    final dynamic divisionIdValue = json['division_id'];
    final dynamic divisionNameValue = json['division_name'];
    final dynamic departmentNameValue = json['department_name'];
    final dynamic yearValue = json['year'];
    final dynamic semesterValue = json['semester'];
    final dynamic isMappedValue = json['is_mapped'];

    return TeacherSubjects(
      id: json['id'],
      subjectCode: codeValue.toString(),
      subjectName: nameValue.toString(),
      strength: strengthValue is int ? strengthValue : int.tryParse(strengthValue.toString()) ?? 0,
      divisionId: divisionIdValue is int ? divisionIdValue : int.tryParse(divisionIdValue.toString()),
      divisionName: divisionNameValue?.toString(),
      departmentName: departmentNameValue?.toString(),
      year: yearValue is int ? yearValue : int.tryParse(yearValue.toString()),
      semester: semesterValue is int ? semesterValue : int.tryParse(semesterValue.toString()),
      isMapped: isMappedValue is bool ? isMappedValue : (isMappedValue?.toString().toLowerCase() == 'true' || isMappedValue == null),
    );
  }
}