
class TaskStatus{
   late final String status;
   late final dynamic result;

   TaskStatus({required this.status,required this.result});

  factory TaskStatus.fromJson(Map<String,dynamic> json){
    return TaskStatus(
        status: json['status'],
        result: json['result']
    );
  }
}