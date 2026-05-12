class Departments{
  final int id;
  final String departmentName;

  const Departments({
      required this.id,
      required this.departmentName
  });

  factory Departments.fromJson(Map<String, dynamic> json){
    return Departments(
        id: json['id'],
        departmentName: json['name']
    );
  }

}