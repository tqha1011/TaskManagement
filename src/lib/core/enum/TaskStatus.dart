enum TaskStatus {
  toDo(0),
  completed(1),
  overDue(2);

  final int value;
  const TaskStatus(this.value);

  factory TaskStatus.fromInt(int dbValue){
    return TaskStatus.values.firstWhere(
        (status) => status.value == dbValue,
        orElse: () => TaskStatus.toDo,
    );
  }
}