class TeacherProfile{
  final String name;
  final String email;
  final int totalSubjects;
  final int totalStudents;
  final String department;
  final DateTime dateJoined;

  const TeacherProfile({
    required this.name,
    required this.email,
    required this.totalSubjects,
    required this.totalStudents,
    required this.department,
    required this.dateJoined
});

  factory TeacherProfile.fromJson(Map<String,dynamic> json){
    return TeacherProfile(
      name: json["name"],
      email: json["email"],
      totalSubjects: json["total_subjects"],
      totalStudents: json["total_students"],
      department: json["department_name"],
      dateJoined: DateTime.parse(json["date_joined"])
    );
  }

}