class StudentList{
      final int studentID;
      final String studentName;
      final int totalClasses;
      final int attendedClasses;
      final double attendancePercentage;

      const StudentList({
        required this.studentID,
        required this.studentName,
        required this.totalClasses,
        required this.attendedClasses,
        this.attendancePercentage = 0.0,
      });

      factory StudentList.fromJson(Map<String, dynamic> json) {
        return StudentList(
          studentID: json['student_id'],
          studentName: json['student_name'],
          totalClasses: json['total_classes'],
          attendedClasses: json['attended_classes'],
          attendancePercentage: json['attendance_percentage'],
        );
      }
}