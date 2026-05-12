class PresentAbsenteesStudents{
  final int studentID;
  final String studentName;
  final int studentPRN;

  const PresentAbsenteesStudents({
    required this.studentID,
    required this.studentName,
    required this.studentPRN,
  });

  factory PresentAbsenteesStudents.fromJson(Map<String,dynamic> json){
    return PresentAbsenteesStudents(
        studentID: json["student_id"],
        studentName: json["student_name"],
        studentPRN: json["student_prn"]
    );
  }
}