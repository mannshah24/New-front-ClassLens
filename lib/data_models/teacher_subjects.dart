class TeacherSubjects{
  final int id;
  final String subjectCode;
  final String subjectName;
  final int strength;
  final int? divisionId;
  final String? divisionName;

  const TeacherSubjects({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.strength,
    this.divisionId,
    this.divisionName,
  });

  factory TeacherSubjects.fromJson(Map<String,dynamic> json){
    final dynamic codeValue = json['code'] ?? json['subject_code'] ?? json['subject__code'] ?? '';
    final dynamic nameValue = json['name'] ?? json['subject_name'] ?? json['subject__name'] ?? '';
    final dynamic strengthValue = json['strength'] ?? json['student_count'] ?? 0;
    final dynamic divisionIdValue = json['division_id'];
    final dynamic divisionNameValue = json['division_name'];

    return TeacherSubjects(
      id: json['id'],
      subjectCode: codeValue.toString(),
      subjectName: nameValue.toString(),
      strength: strengthValue is int ? strengthValue : int.tryParse(strengthValue.toString()) ?? 0,
      divisionId: divisionIdValue is int ? divisionIdValue : int.tryParse(divisionIdValue.toString()),
      divisionName: divisionNameValue?.toString(),
    );
  }
}