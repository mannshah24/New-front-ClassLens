class Subjects{
  final int id;
  final String code;
  final String name;

  const Subjects({
    required this.id,
    required this.code,
    required this.name
  });

  factory Subjects.fromJson(Map<String,dynamic> json){
    return Subjects(
      id: json['id'],
      code:json['code'],
      name: json['name']
    );
  }
}