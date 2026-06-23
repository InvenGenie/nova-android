class Subject {
  final int subjectId;
  final String subjectName;

  Subject({required this.subjectId, required this.subjectName});

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    subjectId: json['subject_id'] ?? 0,
    subjectName: json['subject_name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'subject_id': subjectId,
    'subject_name': subjectName,
  };
}
